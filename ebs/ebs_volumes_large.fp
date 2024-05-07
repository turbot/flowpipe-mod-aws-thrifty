locals {
  ebs_volumes_large_query = <<-EOQ
  select
    concat(volume_id, ' [', region, '/', account_id, ']') as title,
    volume_id,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_ebs_volume
  where
    size > ${var.ebs_volume_max_size_gb}::int
  EOQ
}

trigger "query" "detect_and_respond_to_ebs_volumes_large" {
  title       = "Detect and respond to large EBS volumes"
  description = "Detects large EBS volumes and responds with your chosen action."

  enabled  = var.ebs_volumes_large_trigger_enabled
  schedule = var.ebs_volumes_large_trigger_schedule
  database = var.database
  sql      = local.ebs_volumes_large_query

  capture "insert" {
    pipeline = pipeline.respond_to_ebs_volumes_large
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_ebs_volumes_large" {
  title       = "Detect and respond to large EBS volumes"
  description = "Detects large EBS volumes and responds with your chosen action."
  // tags          = merge(local.ebs_common_tags, { class = "deprecated" })

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
    default     = var.ebs_volume_large_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_large_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_volumes_large_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_ebs_volumes_large
    args = {
      items                    = step.query.detect.rows
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
    }
  }
}

pipeline "respond_to_ebs_volumes_large" {
  title       = "Respond to large EBS volumes"
  description = "Responds to a collection of large EBS volumes."
  // tags          = merge(local.ebs_common_tags, { class = "deprecated" })

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
    default     = var.ebs_volume_large_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_large_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} large EBS volumes."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.volume_id => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_ebs_volume_large
    args = {
      title                    = each.value.title
      volume_id                = each.value.volume_id
      region                   = each.value.region
      cred                     = each.value.cred
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
    }
  }
}

pipeline "respond_to_ebs_volume_large" {
  title       = "Respond to large EBS volume"
  description = "Responds to a large EBS volume."
  // tags          = merge(local.ebs_common_tags, { class = "deprecated" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "volume_id" {
    type        = string
    description = "The ID of the EBS volume."
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
    default     = var.ebs_volume_large_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_large_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected large EBS Volume ${param.title}."
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
      actions = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.StyleInfo
          pipeline_ref = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped large EBS Volume ${param.title}."
          }
          success_msg = "Skipped EBS Volume ${param.title}."
          error_msg   = "Error skipping EBS Volume ${param.title}."
        },
        "delete_volume" = {
          label        = "Delete_volume"
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