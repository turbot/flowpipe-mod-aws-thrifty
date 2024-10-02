locals {
  ebs_volumes_with_low_iops_query = <<-EOQ
  select
    concat(volume_id, ' [', volume_type, '/', region, '/', account_id, ']') as title,
    volume_id,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_ebs_volume
  where
    volume_type in ('io1', 'io2')
    and iops <= 16000
  EOQ
}

trigger "query" "detect_and_correct_ebs_volumes_with_low_iops" {
  title         = "Detect & correct EBS volumes with low IOPS"
  description   = "Detects EBS volumes with low IOPS and runs your chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_volumes_with_low_iops_trigger.md")
  tags          = merge(local.ebs_common_tags, { class = "managed" })

  enabled  = var.ebs_volumes_with_low_iops_trigger_enabled
  schedule = var.ebs_volumes_with_low_iops_trigger_schedule
  database = var.database
  sql      = local.ebs_volumes_with_low_iops_query

  capture "insert" {
    pipeline = pipeline.correct_ebs_volumes_with_low_iops
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ebs_volumes_with_low_iops" {
  title         = "Detect & correct EBS volumes with low IOPS"
  description   = "Detects EBS volumes with low IOPS and runs your chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_volumes_with_low_iops.md")
  tags          = merge(local.ebs_common_tags, { class = "managed", type = "recommended" })

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
    default     = var.ebs_volumes_with_low_iops_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_with_low_iops_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_volumes_with_low_iops_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ebs_volumes_with_low_iops
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

pipeline "correct_ebs_volumes_with_low_iops" {
  title         = "Correct EBS volumes with low IOPS"
  description   = "Runs corrective action on a collection of EBS volumes with low IOPS."
  documentation = file("./pipelines/ebs/docs/correct_ebs_volumes_with_low_iops.md")
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
    default     = var.ebs_volumes_with_low_iops_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_with_low_iops_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EBS volumes with low IOPS."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.volume_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ebs_volume_with_low_iops
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

pipeline "correct_one_ebs_volume_with_low_iops" {
  title         = "Correct one EBS volume with low IOPS"
  description   = "Runs corrective action on an EBS volume with low IOPS."
  documentation = file("./pipelines/ebs/docs/correct_one_ebs_volume_with_low_iops.md")
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
    default     = var.ebs_volumes_with_low_iops_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_with_low_iops_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected EBS Volume ${param.title} with low IOPS."
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
            text     = "Skipped EBS Volume ${param.title} with low IOPS."
          }
          success_msg = "Skipped EBS Volume ${param.title}."
          error_msg   = "Error skipping EBS Volume ${param.title}."
        },
        "update_to_gp3" = {
          label        = "Update to gp3"
          value        = "update_to_gp3"
          style        = local.style_ok
          pipeline_ref = local.aws_pipeline_modify_ebs_volume
          pipeline_args = {
            volume_id   = param.volume_id
            volume_type = "gp3"
            region      = param.region
            cred        = param.cred
          }
          success_msg = "Updated EBS volume ${param.title} to gp3."
          error_msg   = "Error updating EBS volume ${param.title} to gp3."
        }
      }
    }
  }
}

variable "ebs_volumes_with_low_iops_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_with_low_iops_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_with_low_iops_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_with_low_iops_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_volume"]
  tags = {
    folder = "Advanced/EBS"
  }
}