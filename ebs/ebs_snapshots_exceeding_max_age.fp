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

trigger "query" "detect_and_respond_to_ebs_snapshots_exceeding_max_age" {
  title       = "Detect and respond to EBS snapshots exceeding max age"
  description = "Detects EBS snapshots exceeding max age and responds with your chosen action."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = local.ebs_snapshots_exceeding_max_age_query

  capture "insert" {
    pipeline = pipeline.respond_to_ebs_snapshots_exceeding_max_age
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_ebs_snapshots_exceeding_max_age" {
  title         = "Detect and respond to EBS snapshots exceeding max age"
  description   = "Detects EBS snapshots exceeding max age and responds with your chosen action."
  documentation = file("./ebs/ebs_snapshots_exceeding_max_age.md")
  tags          = merge(local.ebs_common_tags, { class = "unused" })

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

  param "notifier_level" {
    type        = string
    description = local.NotifierLevelDescription
    default     = var.notifier_level
  }

  param "approvers" {
    type        = list(string)
    description = local.ApproversDescription
    default     = var.approvers
  }

  param "default_response" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.ebs_snapshot_age_max_days_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_snapshot_age_max_days_responses
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_snapshots_exceeding_max_age_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_ebs_snapshots_exceeding_max_age
    args     = {
      items            = step.query.detect.rows
      notifier         = param.notifier
      notifier_level   = param.notifier_level
      approvers        = param.approvers
      default_response = param.default_response
      responses        = param.responses
    }
  }
}

pipeline "respond_to_ebs_snapshots_exceeding_max_age" {
  title         = "Respond to EBS snapshots exceeding max age"
  description   = "Responds to a collection of EBS snapshots exceeding max age."
  documentation = file("./ebs/ebs_snapshots_exceeding_max_age.md")
  tags          = merge(local.ebs_common_tags, { class = "unused" })

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

  param "notifier_level" {
    type        = string
    description = local.NotifierLevelDescription
    default     = var.notifier_level
  }

  param "approvers" {
    type        = list(string)
    description = local.ApproversDescription
    default     = var.approvers
  }

  param "default_response" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.ebs_snapshot_age_max_days_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_snapshot_age_max_days_responses
  }

  step "message" "notify_detection_count" {
    if       = var.notifier_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EBS Snapshots exceeding maximum age."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.snapshot_id => row }
  }

  step "pipeline" "respond_to_item" {
    for_each = step.transform.items_by_id
    pipeline = pipeline.respond_to_ebs_snapshot_exceeding_max_age
    args     = {
      title            = each.value.title
      snapshot_id      = each.value.snapshot_id
      region           = each.value.region
      cred             = each.value.cred
      notifier         = param.notifier
      notifier_level   = param.notifier_level
      approvers        = param.approvers
      default_response = param.default_response
      responses        = param.responses
    }
  }
}

pipeline "respond_to_ebs_snapshot_exceeding_max_age" {
  title         = "Respond to EBS snapshot exceeding max age"
  description   = "Responds to an EBS snapshot exceeding max age."
  documentation = file("./ebs/ebs_snapshots_exceeding_max_age.md")
  tags          = merge(local.ebs_common_tags, { class = "unused" })

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

  param "notifier_level" {
    type        = string
    description = local.NotifierLevelDescription
    default     = var.notifier_level
  }

  param "approvers" {
    type        = list(string)
    description = local.ApproversDescription
    default     = var.approvers
  }

  param "default_response" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.ebs_snapshot_age_max_days_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_snapshot_age_max_days_responses
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args     = {
      notifier         = param.notifier
      notifier_level   = param.notifier_level
      approvers        = param.approvers
      detect_msg       = "Detected EBS Snapshot ${param.title} exceeding maximum age."
      default_response = param.default_response
      responses        = param.responses
      response_options = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.StyleInfo
          pipeline_ref  = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notifier_level == local.NotifierLevelVerbose
            text     = "Skipped EBS Snapshot ${param.title} exceeding maximum age."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete" = {
          label  = "Delete"
          value  = "delete"
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