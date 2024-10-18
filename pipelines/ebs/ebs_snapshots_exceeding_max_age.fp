locals {
  ebs_snapshots_exceeding_max_age_query = <<-EOQ
  select
    concat(snapshot_id, ' [', region, '/', account_id, ']') as title,
    snapshot_id,
    region,
    sp_connection_name as conn
  from
    aws_ebs_snapshot
  where
    (current_timestamp - (${var.ebs_snapshots_exceeding_max_age_days}::int || ' days')::interval) > start_time
  EOQ

  ebs_snapshots_exceeding_max_age_default_action_enum = ["notify", "skip", "delete_snapshot"]
  ebs_snapshots_exceeding_max_age_enabled_actions_enum = ["skip", "delete_snapshot"]
}

variable "ebs_snapshots_exceeding_max_age_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_snapshots_exceeding_max_age_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_snapshots_exceeding_max_age_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "delete_snapshot"]
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_snapshots_exceeding_max_age_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_snapshot"]
  enum        = ["skip", "delete_snapshot"]
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_snapshots_exceeding_max_age_days" {
  type        = number
  description = "The maximum number of days EBS snapshots can be retained."
  default     = 90
  tags = {
    folder = "Advanced/EBS"
  }
}

trigger "query" "detect_and_correct_ebs_snapshots_exceeding_max_age" {
  title         = "Detect & correct EBS snapshots exceeding max age"
  description   = "Detects EBS snapshots exceeding max age and runs your chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_snapshots_exceeding_max_age_trigger.md")
  tags          = merge(local.ebs_common_tags, { class = "unused" })

  enabled  = var.ebs_snapshots_exceeding_max_age_trigger_enabled
  schedule = var.ebs_snapshots_exceeding_max_age_trigger_schedule
  database = var.database
  sql      = local.ebs_snapshots_exceeding_max_age_query

  capture "insert" {
    pipeline = pipeline.correct_ebs_snapshots_exceeding_max_age
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ebs_snapshots_exceeding_max_age" {
  title         = "Detect & correct EBS snapshots exceeding max age"
  description   = "Detects EBS snapshots exceeding max age and runs your chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_snapshots_exceeding_max_age.md")
  tags          = merge(local.ebs_common_tags, { class = "unused", recommended = "true" })

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
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ebs_snapshots_exceeding_max_age_default_action
    enum        = local.ebs_snapshots_exceeding_max_age_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_snapshots_exceeding_max_age_enabled_actions
    enum        = local.ebs_snapshots_exceeding_max_age_enabled_actions_enum
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_snapshots_exceeding_max_age_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ebs_snapshots_exceeding_max_age
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

pipeline "correct_ebs_snapshots_exceeding_max_age" {
  title         = "Correct EBS snapshots exceeding max age"
  description   = "Runs corrective action on a collection of EBS snapshots exceeding max age."
  documentation = file("./pipelines/ebs/docs/correct_ebs_snapshots_exceeding_max_age.md")
  tags          = merge(local.ebs_common_tags, { class = "unused", folder = "Internal" })

  param "items" {
    type = list(object({
      title       = string
      snapshot_id = string
      region      = string
      conn        = string
    }))
    description = local.description_items
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
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ebs_snapshots_exceeding_max_age_default_action
    enum        = local.ebs_snapshots_exceeding_max_age_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_snapshots_exceeding_max_age_enabled_actions
    enum        = local.ebs_snapshots_exceeding_max_age_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected ${length(param.items)} EBS snapshots exceeding maximum age."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.snapshot_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ebs_snapshot_exceeding_max_age
    args = {
      title              = each.value.title
      snapshot_id        = each.value.snapshot_id
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

pipeline "correct_one_ebs_snapshot_exceeding_max_age" {
  title         = "Correct one EBS snapshot exceeding max age"
  description   = "Runs corrective action on an EBS snapshot exceeding max age."
  documentation = file("./pipelines/ebs/docs/correct_one_ebs_snapshot_exceeding_max_age.md")
  tags          = merge(local.ebs_common_tags, { class = "unused", folder = "Internal" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "snapshot_id" {
    type        = string
    description = "The ID of the EBS snapshot."
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
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ebs_snapshots_exceeding_max_age_default_action
    enum        = local.ebs_snapshots_exceeding_max_age_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_snapshots_exceeding_max_age_enabled_actions
    enum        = local.ebs_snapshots_exceeding_max_age_enabled_actions_enum
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected EBS snapshot ${param.title} exceeding maximum age."
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
            text     = "Skipped EBS snapshot ${param.title} exceeding maximum age."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete_snapshot" = {
          label        = "Delete Snapshot"
          value        = "delete_snapshot"
          style        = local.style_alert
          pipeline_ref = aws.pipeline.delete_ebs_snapshot
          pipeline_args = {
            snapshot_id = param.snapshot_id
            region      = param.region
            conn        = param.conn
          }
          success_msg = "Deleted EBS snapshot ${param.title}."
          error_msg   = "Error deleting EBS snapshot ${param.title}."
        }
      }
    }
  }
}
