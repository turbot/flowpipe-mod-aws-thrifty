locals {
  ebs_volumes_with_high_iops_query = <<-EOQ
  select
    concat(volume_id, ' [', region, '/', account_id, ']') as title,
    volume_id,
    region,
    _ctx ->> 'connection_name' as credential
  from
    aws_ebs_volume
  where
    volume_type in ('io1', 'io2')
    and iops > ${var.ebs_volumes_with_high_iops}::int
  EOQ
}

trigger "query" "detect_and_correct_ebs_volumes_with_high_iops" {
  title       = "Detect & Correct EBS volumes with high IOPS"
  description = "Detects EBS volumes with high IOPS and runs your chosen corrective action."

  enabled  = var.ebs_volumes_with_high_iops_trigger_enabled
  schedule = var.ebs_volumes_with_high_iops_trigger_schedule
  database = var.database
  sql      = local.ebs_volumes_with_high_iops_query

  capture "insert" {
    pipeline = pipeline.correct_ebs_volumes_with_high_iops
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ebs_volumes_with_high_iops" {
  title       = "Detect & Correct EBS volumes with high IOPS"
  description = "Detects EBS volumes with high IOPS and runs your chosen corrective action."

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
    default     = var.ebs_volumes_with_high_iops_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_with_high_iops_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_volumes_with_high_iops_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ebs_volumes_with_high_iops
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

pipeline "correct_ebs_volumes_with_high_iops" {
  title       = "Correct EBS volumes with high IOPS"
  description = "Runs corrective action on a collection of EBS volumes with high IOPS."

  param "items" {
    type = list(object({
      title      = string
      volume_id  = string
      region     = string
      credential = string
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
    default     = var.ebs_volumes_with_high_iops_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_with_high_iops_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EBS volumes with high IOPS."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.volume_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ebs_volume_with_high_iops
    args = {
      title              = each.value.title
      volume_id          = each.value.volume_id
      region             = each.value.region
      credential         = each.value.credential
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_one_ebs_volume_with_high_iops" {
  title       = "Correct one EBS volume with high IOPS"
  description = "Runs corrective action on an EBS volume with high IOPS."

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

  param "credential" {
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
    default     = var.ebs_volumes_with_high_iops_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_with_high_iops_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected EBS volume ${param.title} with high IOPS."
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
            text     = "Skipped EBS volume ${param.title} with high IOPS."
          }
          success_msg = "Skipped EBS volume ${param.title}."
          error_msg   = "Error skipping EBS volume ${param.title}."
        },
        "delete_volume" = {
          label        = "Delete volume"
          value        = "delete_volume"
          style        = local.style_alert
          pipeline_ref = local.aws_pipeline_delete_ebs_volume
          pipeline_args = {
            volume_id  = param.volume_id
            region     = param.region
            credential = param.credential
          }
          success_msg = "Deleted EBS volume ${param.title}."
          error_msg   = "Error deleting EBS volume ${param.title}."
        }
      }
    }
  }
}

variable "ebs_volumes_with_high_iops_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_volumes_with_high_iops_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ebs_volumes_with_high_iops_default_action" {
  type        = string
  description = "The default response to use when EBS volumes with high iops."
  default     = "notify"
}

variable "ebs_volumes_with_high_iops_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_volume"]
}

variable "ebs_volumes_with_high_iops" {
  type        = number
  description = "The maximum IOPS allowed for volumes."
  default     = 32000
}