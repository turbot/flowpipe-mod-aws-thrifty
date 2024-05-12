locals {
  ebs_volumes_exceeding_max_size_query = <<-EOQ
  select
    concat(volume_id, ' [', region, '/', account_id, ']') as title,
    volume_id,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_ebs_volume
  where
    size > ${var.ebs_volumes_exceeding_max_size}::int
  EOQ
}

trigger "query" "detect_and_correct_ebs_volumes_exceeding_max_size" {
  title         = "Detect & correct EBS volumes exceeding max size"
  description   = "Detects EBS volumes exceeding maximum size and runs your chosen action."
  documentation = file("./ebs/docs/detect_and_correct_ebs_volumes_exceeding_max_size_trigger.md")
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
  documentation = file("./ebs/docs/detect_and_correct_ebs_volumes_exceeding_max_size.md")
  tags          = merge(local.ebs_common_tags, { class = "managed", type = "featured" })

  param "database" {
    type        = string
    description = local.description_database
    default     = var.database
  }

  param "notifier" {
    type        = string
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(string)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ebs_volumes_exceeding_max_size_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_exceeding_max_size_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_volumes_exceeding_max_size_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ebs_volumes_exceeding_max_size
    args = {
      items                    = step.query.detect.rows
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action           = param.default_action
      enabled_actions          = param.enabled_actions
    }
  }
}

pipeline "correct_ebs_volumes_exceeding_max_size" {
  title         = "Correct EBS volumes exceeding max size"
  description   = "Runs corrective action on a collection of EBS volumes exceeding maximum size."
  documentation = file("./ebs/docs/correct_ebs_volumes_exceeding_max_size.md")
  tags          = merge(local.ebs_common_tags, { class = "managed" })

  param "items" {
    type = list(object({
      title     = string
      volume_id = string
      region    = string
      cred      = string
    }))
  }

  param "notifier" {
    type        = string
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(string)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ebs_volumes_exceeding_max_size_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_exceeding_max_size_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
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
      cred               = each.value.cred
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
  documentation = file("./ebs/docs/correct_one_ebs_volume_exceeding_max_size.md")
  tags          = merge(local.ebs_common_tags, { class = "managed" })

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

  param "cred" {
    type        = string
    description = local.description_credential
  }

  param "notifier" {
    type        = string
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(string)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ebs_volumes_exceeding_max_size_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_exceeding_max_size_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected EBS volume ${param.title} exceeding maximum size."
      default_action           = param.default_action
      enabled_actions          = param.enabled_actions
      actions = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.style_info
          pipeline_ref = local.pipeline_optional_message
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
          pipeline_ref = local.aws_pipeline_delete_ebs_volume
          pipeline_args = {
            volume_id = param.volume_id
            region    = param.region
            cred      = param.cred
          }
          success_msg = "Deleted EBS volume ${param.title}."
          error_msg   = "Error deleting EBS volume ${param.title}."
        }
      }
    }
  }
}

variable "ebs_volumes_exceeding_max_size_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_volumes_exceeding_max_size_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ebs_volumes_exceeding_max_size_default_action" {
  type        = string
  description = "The default action to take for EBS volumes exceeding maximum size."
  default     = "notify"
}

variable "ebs_volumes_exceeding_max_size_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_volume"]
}

variable "ebs_volumes_exceeding_max_size" {
  type        = number
  description = "The maximum size (GB) allowed for volumes."
  default     = 100
}