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
    (current_timestamp - (${var.ebs_snapshot_age_max_days}::int || ' days')::interval) > start_time
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
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ebs_snapshots_exceeding_max_age" {
  title         = "Detect & correct EBS snapshots exceeding max age"
  description   = "Detects EBS snapshots exceeding max age and runs your chosen action."
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
    default     = var.ebs_snapshot_age_max_days_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_snapshot_age_max_days_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_snapshots_exceeding_max_age_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ebs_snapshots_exceeding_max_age
    args     = {
      items                    = step.query.detect.rows
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
    }
  }
}

pipeline "correct_ebs_snapshots_exceeding_max_age" {
  title         = "Corrects EBS snapshots exceeding max age"
  description   = "Runs corrective action on a collection of EBS snapshots exceeding max age."
  // tags          = merge(local.ebs_common_tags, { class = "unused" })

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
    default     = var.ebs_snapshot_age_max_days_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_snapshot_age_max_days_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EBS Snapshots exceeding maximum age."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.snapshot_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ebs_snapshot_exceeding_max_age
    args            = {
      title                    = each.value.title
      snapshot_id              = each.value.snapshot_id
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

pipeline "correct_one_ebs_snapshot_exceeding_max_age" {
  title         = "Correct one EBS snapshot exceeding max age"
  description   = "Runs corrective action on an EBS snapshot exceeding max age."
  // tags          = merge(local.ebs_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "snapshot_id" {
    type        = string
    description = "The ID of the EBS snapshot."
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
    default     = var.ebs_snapshot_age_max_days_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_snapshot_age_max_days_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args     = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected EBS Snapshot ${param.title} exceeding maximum age."
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
      actions = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.StyleInfo
          pipeline_ref  = local.pipeline_optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped EBS Snapshot ${param.title} exceeding maximum age."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete_snapshot" = {
          label  = "Delete Snapshot"
          value  = "delete_snapshot"
          style  = local.StyleAlert
          pipeline_ref  = local.aws_pipeline_delete_ebs_snapshot
          pipeline_args = {
            snapshot_id = param.snapshot_id
            region      = param.region
            cred        = param.cred
          }
          success_msg = "Deleted EBS Snapshot ${param.title}."
          error_msg   = "Error deleting EBS Snapshot ${param.title}."
        }
      }
    }
  }
}