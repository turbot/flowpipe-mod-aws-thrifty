locals {
  rds_db_instances_low_connection_count_query = <<-EOQ
  with rds_db_usage as (
  select
    db_instance_identifier,
    round(sum(maximum) / count(maximum)) as avg_max,
    region,
    account_id,
    _ctx
  from
    aws_rds_db_instance_metric_connections_daily
  where
    date_part('day', now() - timestamp) <= 30
  group by
    db_instance_identifier,
    region,
    account_id,
    _ctx
  )
  select
    concat(db_instance_identifier, ' [', region, '/', account_id, ']') as title,
    db_instance_identifier,
    region,
    _ctx ->> 'connection_name' as cred
  from
    rds_db_usage
  where
    avg_max = 0
  EOQ
}

trigger "query" "detect_and_correct_to_rds_db_instances_low_connection_count" {
  title       = "Detect and correct to RDS DB instances with low connection count"
  description = "Detects RDS DB instances with low connection count and runs your chosen action."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = local.rds_db_instances_low_connection_count_query

  capture "insert" {
    pipeline = pipeline.correct_to_rds_db_instances_low_connection_count
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_to_rds_db_instances_low_connection_count" {
  title       = "Detect and correct to RDS DB instances with low connection count"
  description = "Detects RDS DB instances with low connection count and runs your chosen action."

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
    default     = var.rds_db_instance_low_connection_count_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.rds_db_instance_low_connection_count_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.rds_db_instances_low_connection_count_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_to_rds_db_instances_low_connection_count
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

pipeline "correct_to_rds_db_instances_low_connection_count" {
  title       = "Corrects RDS DB instances with low connection count"
  description = "Runs corrective action on a collection of RDS DB instances with low connection count."

  param "items" {
    type = list(object({
      title                  = string
      db_instance_identifier = string
      region                 = string
      cred                   = string
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
    default     = var.rds_db_instance_low_connection_count_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.rds_db_instance_low_connection_count_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} RDS DB instances with low connection count."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.db_instance_identifier => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_to_rds_db_instance_low_connection_count
    args = {
      title                  = each.value.title
      db_instance_identifier = each.value.db_instance_identifier
      region                 = each.value.region
      cred                   = each.value.cred
      notifier               = param.notifier
      notification_level     = param.notification_level
      approvers              = param.approvers
      default_action         = param.default_action
      enabled_actions        = param.enabled_actions
    }
  }
}

pipeline "correct_to_rds_db_instance_low_connection_count" {
  title       = "Correct an RDS DB instance with low connection count"
  description = "Runs corrective action on an RDS DB instance with low connection count."

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "db_instance_identifier" {
    type        = string
    description = "The identifier of DB instance."
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
    default     = var.rds_db_instance_low_connection_count_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.rds_db_instance_low_connection_count_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected RDS DB instance ${param.title} with low connection count."
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
      response_options = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.StyleInfo
          pipeline_ref = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped RDS DB Instance ${param.title} with low connection count."
          }
          success_msg = "Skipped RDS DB Instance ${param.title}."
          error_msg   = "Error skipping RDS DB Instance ${param.title}."
        },
        "delete_instance" = {
          label        = "Delete Instance"
          value        = "delete_instance"
          style        = local.StyleAlert
          pipeline_ref = local.aws_pipeline_delete_rds_db_instance
          pipeline_args = {
            db_instance_identifier = param.db_instance_identifier
            region                 = param.region
            cred                   = param.cred
          }
          success_msg = "Deleted RDS DB Instance ${param.title}."
          error_msg   = "Error deleting RDS DB Instance ${param.title}."
        }
      }
    }
  }
}