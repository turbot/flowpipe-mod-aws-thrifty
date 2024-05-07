locals {
  ebs_volumes_unattached_query = <<-EOQ
  select
    concat(volume_id, ' [', volume_type, '/', region, '/', account_id, ']') as title,
    volume_id,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_ebs_volume
  where
    jsonb_array_length(attachments) = 0;
  EOQ
}

trigger "query" "detect_and_correct_ebs_volumes_unattached" {
  title       = "Detect & correct EBS volumes unattached"
  description = "Detects EBS volumes which are unattached and runs your chosen action."
  //tags          = merge(local.ebs_common_tags, { class = "unused" })

  enabled  = var.ebs_volumes_unattached_trigger_enabled
  schedule = var.ebs_volumes_unattached_trigger_schedule
  database = var.database
  sql      = local.ebs_volumes_unattached_query

  capture "insert" {
    pipeline = pipeline.correct_ebs_volumes_unattached
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ebs_volumes_unattached" {
  title         = "Detect & correct EBS volumes unattached"
  description   = "Detects EBS volumes which are unattached and runs your chosen action."
  // tags          = merge(local.ebs_common_tags, { class = "unused" })

  param "database" {
    type        = string
    description = local.DatabaseDescription
    default     = var.database
  }

  param "notifier" {
    type        = string
    description = local.NotifierDescription
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.NotifierLevelDescription
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(string)
    description = local.ApproversDescription
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.ebs_volume_unattached_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_unattached_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_volumes_unattached_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ebs_volumes_unattached
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

pipeline "correct_ebs_volumes_unattached" {
  title         = "Corrects EBS volumes unattached"
  description   = "Runs corrective action on a collection of EBS volumes which are unattached."
  // tags          = merge(local.ebs_common_tags, { class = "unused" })

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
    description = local.NotifierDescription
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.NotifierLevelDescription
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(string)
    description = local.ApproversDescription
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.ebs_volume_unattached_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_unattached_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EBS volumes unattached."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.volume_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_ebs_volume_unattached
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

pipeline "correct_ebs_volume_unattached" {
  title         = "Correct one EBS volume unattached"
  description   = "Runs corrective action on an EBS volume unattached."
  // tags          = merge(local.ebs_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "volume_id" {
    type        = string
    description = "EBS volume ID."
  }

  param "region" {
    type        = string
    description = local.RegionDescription
  }

  param "cred" {
    type        = string
    description = local.CredentialDescription
  }

  param "notifier" {
    type        = string
    description = local.NotifierDescription
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.NotifierLevelDescription
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(string)
    description = local.ApproversDescription
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.ebs_volume_unattached_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_unattached_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected EBS volume ${param.title} unattached."
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
      actions = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.StyleInfo
          pipeline_ref = local.pipeline_optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped EBS volume ${param.title} unattached."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete_volume" = {
          label        = "Delete Volume"
          value        = "delete_volume"
          style        = local.StyleAlert
          pipeline_ref = local.aws_pipeline_delete_ebs_volume
          pipeline_args = {
            volume_id = param.volume_id
            region    = param.region
            cred      = param.cred
          }
          success_msg = "Deleted EBS Volume ${param.title}."
          error_msg   = "Error deleting EBS Volume ${param.title}."
        }
      }
    }
  }
}

pipeline "mock_aws_pipeline_delete_ebs_volume" {
  param "volume_id" {
    type = string
  }

  param "region" {
    type = string
  }

  param "cred" {
    type = string
  }

  output "result" {
    value = "Mocked: Delete EBS Volume [Volume_ID: ${param.volume_id}, Region: ${param.region}, Cred: ${param.cred}]"
  }
}