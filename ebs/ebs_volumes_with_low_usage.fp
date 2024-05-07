locals {
  ebs_volumes_with_low_usage_query = <<-EOQ
  with ebs_usage as (
  select
    account_id,
    _ctx,
    region,
    volume_id,
    round(avg(max)) as avg_max
  from
    (
      (
        select
          partition,
          account_id,
          _ctx,
          region,
          volume_id,
          cast(maximum as numeric) as max
        from
          aws_ebs_volume_metric_read_ops_daily
        where
          date_part('day', now() - timestamp) <= 30
      )
      UNION
      (
        select
          partition,
          account_id,
          _ctx,
          region,
          volume_id,
          cast(maximum as numeric) as max
        from
          aws_ebs_volume_metric_write_ops_daily
        where
          date_part('day', now() - timestamp) <= 30
      )
    ) as read_and_write_ops
  group by
    1,
    2,
    3,
    4,
    5
  )
  select
    concat(volume_id, ' [', region, '/', account_id, ']') as title,
    volume_id,
    region,
    _ctx ->> 'connection_name' as cred
  from
    ebs_usage
  where
    avg_max <= ${var.ebs_volume_avg_read_write_ops_low}::int
  EOQ
}

trigger "query" "detect_and_correct_ebs_volumes_with_low_usage" {
  title       = "Detect & correct EBS volumes with low usage"
  description = "Detects EBS volumes with low usage and runs your chosen action."

  enabled  = var.ebs_volumes_with_low_usage_trigger_enabled
  schedule = var.ebs_volumes_with_low_usage_trigger_schedule
  database = var.database
  sql      = local.ebs_volumes_with_low_usage_query

  capture "insert" {
    pipeline = pipeline.correct_ebs_volumes_with_low_usage
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ebs_volumes_with_low_usage" {
  title       = "Detect & correct EBS volumes with low usage"
  description = "Detects EBS volumes with low usage and runs your chosen action."
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
    default     = var.ebs_volume_with_low_usage_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_with_low_usage_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_volumes_with_low_usage_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ebs_volumes_with_low_usage
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

pipeline "correct_ebs_volumes_with_low_usage" {
  title       = "Corrects EBS volumes with low usage"
  description = "Runs corrective action on a collection of EBS volumes with low usage."
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
    default     = var.ebs_volume_with_low_usage_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_with_low_usage_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EBS volumes with low usage."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.volume_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_ebs_volume_with_low_usage
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

pipeline "correct_ebs_volume_with_low_usage" {
  title       = "Correct one EBS volume with low usage"
  description = "Runs corrective action on an EBS volume with low usage."
  // tags          = merge(local.ebs_common_tags, { class = "unused" })

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
    default     = var.ebs_volume_with_low_usage_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_with_low_usage_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected EBS Volume ${param.title} with low usage."
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
            text     = "Skipped EBS Volume ${param.title} with low usage."
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