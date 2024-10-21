locals {
  ebs_volumes_exceeding_max_size_query = <<-EOQ
  select
    concat(volume_id, ' [', volume_type, '/', region, '/', account_id, ']') as title,
    volume_id,
    region,
    sp_connection_name as conn
  from
    aws_ebs_volume
  where
    size > ${var.ebs_volumes_exceeding_max_size}::int
  EOQ

  ebs_volumes_exceeding_max_size_default_action_enum  = ["notify", "skip", "delete_volume", "snapshot_and_delete_volume"]
  ebs_volumes_exceeding_max_size_enabled_actions_enum = ["skip", "delete_volume", "snapshot_and_delete_volume"]
}

variable "ebs_volumes_exceeding_max_size_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_exceeding_max_size_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_exceeding_max_size_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "delete_volume", "snapshot_and_delete_volume"]
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_exceeding_max_size_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_volume", "snapshot_and_delete_volume"]
  enum        = ["skip", "delete_volume", "snapshot_and_delete_volume"]
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_exceeding_max_size" {
  type        = number
  description = "The maximum size (GB) allowed for volumes."
  default     = 100
  tags = {
    folder = "Advanced/EBS"
  }
}

trigger "query" "detect_and_correct_ebs_volumes_exceeding_max_size" {
  title         = "Detect & correct EBS volumes exceeding max size"
  description   = "Detects EBS volumes exceeding maximum size and runs your chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_volumes_exceeding_max_size_trigger.md")
  tags          = merge(local.ebs_common_tags, { class = "managed" })

  enabled  = var.ebs_volumes_exceeding_max_size_trigger_enabled
  schedule = var.ebs_volumes_exceeding_max_size_trigger_schedule
  database = var.database
  sql      = local.ebs_volumes_exceeding_max_size_query

  capture "insert" {
    pipeline = pipeline.correct_ebs_volumes_exceeding_max_size
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ebs_volumes_exceeding_max_size" {
  title         = "Detect & correct EBS volumes exceeding max size"
  description   = "Detects EBS volumes exceeding maximum size and runs your chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_volumes_exceeding_max_size.md")
  tags          = merge(local.ebs_common_tags, { class = "managed", recommended = "true" })

  param "database" {
    type        = connection.steampipe
    description = local.description_database
    default     = var.database
  }

  param "notifier" {
    type        = notifier
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
    enum        = local.notification_level_enum
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ebs_volumes_exceeding_max_size_default_action
    enum        = local.ebs_volumes_exceeding_max_size_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_exceeding_max_size_enabled_actions
    enum        = local.ebs_volumes_exceeding_max_size_enabled_actions_enum
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_volumes_exceeding_max_size_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ebs_volumes_exceeding_max_size
    args = {
      items              = step.query.detect.rows
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_ebs_volumes_exceeding_max_size" {
  title         = "Correct EBS volumes exceeding max size"
  description   = "Runs corrective action on a collection of EBS volumes exceeding maximum size."
  documentation = file("./pipelines/ebs/docs/correct_ebs_volumes_exceeding_max_size.md")
  tags          = merge(local.ebs_common_tags, { class = "managed", folder = "Internal" })

  param "items" {
    type = list(object({
      title     = string
      volume_id = string
      region    = string
      conn      = string
    }))
  }

  param "notifier" {
    type        = notifier
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
    enum        = local.notification_level_enum
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ebs_volumes_exceeding_max_size_default_action
    enum        = local.ebs_volumes_exceeding_max_size_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_exceeding_max_size_enabled_actions
    enum        = local.ebs_volumes_exceeding_max_size_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected ${length(param.items)} EBS volumes exceeding maximum size."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.volume_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ebs_volume_exceeding_max_size
    args = {
      title              = each.value.title
      volume_id          = each.value.volume_id
      region             = each.value.region
      conn               = connection.aws[each.value.conn]
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_one_ebs_volume_exceeding_max_size" {
  title         = "Correct one EBS volume exceeding max size"
  description   = "Runs corrective action on an EBS volume exceeding maximum size."
  documentation = file("./pipelines/ebs/docs/correct_one_ebs_volume_exceeding_max_size.md")
  tags          = merge(local.ebs_common_tags, { class = "managed", folder = "Internal" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "volume_id" {
    type        = string
    description = "The ID of the EBS volume."
  }

  param "region" {
    type        = string
    description = local.description_region
  }

  param "conn" {
    type        = connection.aws
    description = local.description_connection
  }

  param "notifier" {
    type        = notifier
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
    enum        = local.notification_level_enum
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ebs_volumes_exceeding_max_size_default_action
    enum        = local.ebs_volumes_exceeding_max_size_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_exceeding_max_size_enabled_actions
    enum        = local.ebs_volumes_exceeding_max_size_enabled_actions_enum
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected EBS volume ${param.title} exceeding maximum size."
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
      actions = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.style_info
          pipeline_ref = detect_correct.pipeline.optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.level_verbose
            text     = "Skipped EBS volume ${param.title} exceeding maximum size."
          }
          success_msg = "Skipped EBS volume ${param.title}."
          error_msg   = "Error skipping EBS volume ${param.title}."
        },
        "delete_volume" = {
          label        = "Delete Volume"
          value        = "delete_volume"
          style        = local.style_alert
          pipeline_ref = aws.pipeline.delete_ebs_volume
          pipeline_args = {
            volume_id = param.volume_id
            region    = param.region
            conn      = param.conn
          }
          success_msg = "Deleted EBS Volume ${param.title}."
          error_msg   = "Error deleting EBS Volume ${param.title}."
        }
        "snapshot_and_delete_volume" = {
          label        = "Snapshot & Delete Volume"
          value        = "snapshot_and_delete_volume"
          style        = local.style_alert
          pipeline_ref = pipeline.snapshot_and_delete_ebs_volume
          pipeline_args = {
            volume_id = param.volume_id
            region    = param.region
            conn      = param.conn
          }
          success_msg = "Snapshotted & Deleted EBS Volume ${param.title}."
          error_msg   = "Error snapshotting & deleting EBS Volume ${param.title}."
        }
      }
    }
  }
}
