locals {
  ebs_volumes_if_unattached_query = <<-EOQ
  select
    concat(volume_id, ' [', volume_type, '/', region, '/', account_id, ']') as title,
    volume_id,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_ebs_volume
  where
    jsonb_array_length(attachments) = 0
  EOQ
}

trigger "query" "detect_and_correct_ebs_volumes_if_unattached" {
  title         = "Detect & correct EBS volumes if unattached"
  description   = "Detects EBS volumes which are unattached and runs your chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_volumes_if_unattached_trigger.md")
  tags          = merge(local.ebs_common_tags, { class = "unused" })

  enabled  = var.ebs_volumes_if_unattached_trigger_enabled
  schedule = var.ebs_volumes_if_unattached_trigger_schedule
  database = var.database
  sql      = local.ebs_volumes_if_unattached_query

  capture "insert" {
    pipeline = pipeline.correct_ebs_volumes_if_unattached
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ebs_volumes_if_unattached" {
  title         = "Detect & correct EBS volumes if unattached"
  description   = "Detects EBS volumes which are unattached and runs your chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_volumes_if_unattached.md")
  tags          = merge(local.ebs_common_tags, { class = "unused", type = "recommended" })

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
    default     = var.ebs_volumes_if_unattached_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_if_unattached_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_volumes_if_unattached_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ebs_volumes_if_unattached
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

pipeline "correct_ebs_volumes_if_unattached" {
  title         = "Correct EBS volumes if unattached"
  description   = "Runs corrective action on a collection of EBS volumes which are unattached."
  documentation = file("./pipelines/ebs/docs/correct_ebs_volumes_if_unattached.md")
  tags          = merge(local.ebs_common_tags, { class = "unused" })

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
    default     = var.ebs_volumes_if_unattached_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_if_unattached_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EBS volumes unattached."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.volume_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ebs_volume_if_unattached
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

pipeline "correct_one_ebs_volume_if_unattached" {
  title         = "Correct one EBS volume if unattached"
  description   = "Runs corrective action on an EBS volume unattached."
  documentation = file("./pipelines/ebs/docs/correct_one_ebs_volume_if_unattached.md")
  tags          = merge(local.ebs_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "volume_id" {
    type        = string
    description = "EBS volume ID."
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
    default     = var.ebs_volumes_if_unattached_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_if_unattached_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected EBS volume ${param.title} unattached."
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
            text     = "Skipped EBS volume ${param.title} unattached."
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
            cred      = param.cred
          }
          success_msg = "Snapshotted & Deleted EBS Volume ${param.title}."
          error_msg   = "Error snapshotting & deleting EBS Volume ${param.title}."
        }
      }
    }
  }
}

variable "ebs_volumes_if_unattached_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
}

variable "ebs_volumes_if_unattached_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
}

variable "ebs_volumes_if_unattached_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
}

variable "ebs_volumes_if_unattached_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_volume", "snapshot_and_delete_volume"]
}