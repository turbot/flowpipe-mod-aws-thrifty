locals {
  rds_db_instances_long_running_query = <<-EOQ
  select
    concat(db_instance_identifier, ' [', region, '/', account_id, ']') as title,
    db_instance_identifier,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_rds_db_instance
  where
    (current_timestamp - (${var.rds_running_db_instance_age_max_days}::int || ' days')::interval) > create_time
  EOQ
}

trigger "query" "detect_and_correct_rds_db_instances_long_running" {
  title       = "Detect & correct long running RDS DB instances"
  description = "Detects long running RDS DB instances and runs your chosen action."

  enabled  = var.rds_db_instances_long_running_trigger_enabled
  schedule = var.rds_db_instances_long_running_trigger_schedule
  database = var.database
  sql      = local.rds_db_instances_long_running_query

  capture "insert" {
    pipeline = pipeline.correct_to_rds_db_instances_long_running
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_rds_db_instances_long_running" {
  title       = "Detect & correct long running RDS DB instances"
  description = "Detects long running RDS DB instances and runs your chosen action."

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
    default     = var.rds_db_instance_long_running_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.rds_db_instance_long_running_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.rds_db_instances_long_running_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_to_rds_db_instances_long_running
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

pipeline "correct_to_rds_db_instances_long_running" {
  title       = "Corrects long running RDS DB instances"
  description = "Runs corrective action on a collection of long running RDS DB instances."

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
    default     = var.rds_db_instance_long_running_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.rds_db_instance_long_running_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected long running RDS DB instances ${length(param.items)}."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.db_instance_identifier => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_to_rds_db_instance_long_running
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

pipeline "correct_to_rds_db_instance_long_running" {
  title       = "Correct one long running RDS DB instance"
  description = "Runs corrective action on a long running RDS DB instance."

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
    default     = var.rds_db_instance_long_running_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.rds_db_instance_long_running_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected long running RDS DB Instance ${param.title}."
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
      response_options = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.StyleInfo
          pipeline_ref = local.pipeline_optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped long running RDS DB Instance ${param.title}."
          }
          success_msg = ""
          error_msg   = ""
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

pipeline "mock_aws_pipeline_delete_rds_instance" {
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

  output "result" {
    value = "Mocked: Delete RDS Instance [ID: ${param.db_instance_identifier}, Region: ${param.region}, Cred: ${param.cred}]"
  }
}