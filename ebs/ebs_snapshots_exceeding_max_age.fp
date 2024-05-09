locals {
  ebs_snapshots_exceeding_max_age_query = <<-EOQ
  select
    concat(snapshot_id, ' [', region, '/', account_id, ']') as title,
    snapshot_id,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_ebs_snapshot
  where
    (current_timestamp - (${var.ebs_snapshots_age_max_days}::int || ' days')::interval) > start_time
  EOQ
}

trigger "query" "detect_and_correct_ebs_snapshots_exceeding_max_age" {
  title       = "Detect & correct EBS snapshots exceeding max age"
  description = "Detects EBS snapshots exceeding max age and runs your chosen action."

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
  title       = "Detect & correct EBS snapshots exceeding max age"
  description = "Detects EBS snapshots exceeding max age and runs your chosen action."

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
    default     = var.ebs_snapshots_exceeding_max_age_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_snapshots_exceeding_max_age_enabled_actions
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
  title       = "Corrects EBS snapshots exceeding max age"
  description = "Runs corrective action on a collection of EBS snapshots exceeding max age."

  param "items" {
    type = list(object({
      title       = string
      snapshot_id = string
      region      = string
      cred        = string
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
    default     = var.ebs_snapshots_exceeding_max_age_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_snapshots_exceeding_max_age_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
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
      cred               = each.value.cred
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_one_ebs_snapshot_exceeding_max_age" {
  title       = "Correct one EBS snapshot exceeding max age"
  description = "Runs corrective action on an EBS snapshot exceeding max age."

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
    default     = var.ebs_snapshots_exceeding_max_age_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_snapshots_exceeding_max_age_enabled_actions
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
          pipeline_ref = local.pipeline_optional_message
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
          pipeline_ref = local.aws_pipeline_delete_ebs_snapshot
          pipeline_args = {
            snapshot_id = param.snapshot_id
            region      = param.region
            cred        = param.cred
          }
          success_msg = "Deleted EBS snapshot ${param.title}."
          error_msg   = "Error deleting EBS snapshot ${param.title}."
        }
      }
    }
  }
}

variable "ebs_snapshots_exceeding_max_age_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_snapshots_exceeding_max_age_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ebs_snapshots_exceeding_max_age_default_action" {
  type        = string
  description = "The default action to take for EBS snapshots exceeding maximum age."
  default     = "notify"
}

variable "ebs_snapshots_exceeding_max_age_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_snapshot"]
}

variable "ebs_snapshots_age_max_days" {
  type        = number
  description = "The maximum number of days EBS snapshots can be retained."
  default     = 90
}