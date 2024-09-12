locals {
  ebs_volumes_using_gp2_query = <<-EOQ
  select
    concat(volume_id, ' [', volume_type, '/', region, '/', account_id, '/', availability_zone, ']') as title,
    volume_id,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_ebs_volume
  where
    volume_type = 'gp2';
  EOQ
}

trigger "query" "detect_and_correct_ebs_volumes_using_gp2" {
  title         = "Detect & correct EBS volumes using gp2"
  description   = "Detects EBS volumes using gp2 and executes the chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_volumes_using_gp2_trigger.md")
  tags          = merge(local.ebs_common_tags, { class = "deprecated" })

  enabled  = var.ebs_volumes_using_gp2_trigger_enabled
  schedule = var.ebs_volumes_using_gp2_trigger_schedule
  database = var.database
  sql      = local.ebs_volumes_using_gp2_query

  capture "insert" {
    pipeline = pipeline.correct_ebs_volumes_using_gp2
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ebs_volumes_using_gp2" {
  title         = "Detect & correct EBS volumes using gp2"
  description   = "Detects EBS volumes using gp2 and performs the chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_volumes_using_gp2.md")
  tags          = merge(local.ebs_common_tags, { class = "deprecated", type = "recommended" })

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
    default     = var.ebs_volumes_using_gp2_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_using_gp2_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_volumes_using_gp2_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ebs_volumes_using_gp2
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

pipeline "correct_ebs_volumes_using_gp2" {
  title         = "Correct EBS volumes using gp2"
  description   = "Executes corrective actions on EBS volumes using gp2."
  documentation = file("./pipelines/ebs/docs/correct_ebs_volumes_using_gp2.md")
  tags          = merge(local.ebs_common_tags, { class = "deprecated" })

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
    default     = var.ebs_volumes_using_gp2_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_using_gp2_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EBS volumes using gp2."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.volume_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ebs_volume_using_gp2
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

pipeline "correct_one_ebs_volume_using_gp2" {
  title         = "Correct one EBS volume using gp2"
  description   = "Runs corrective action on an EBS volume using gp2."
  documentation = file("./pipelines/ebs/docs/correct_one_ebs_volume_using_gp2.md")
  tags          = merge(local.ebs_common_tags, { class = "deprecated" })

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
    default     = var.ebs_volumes_using_gp2_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_using_gp2_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected EBS volume ${param.title} using gp2."
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
            text     = "Skipped EBS volume ${param.title} using gp2."
          }
          success_msg = ""
          error_msg   = ""
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

variable "ebs_volumes_using_gp2_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_using_gp2_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_using_gp2_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_using_gp2_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "update_to_gp3"]
  tags = {
    folder = "Advanced/EBS"
  }
}