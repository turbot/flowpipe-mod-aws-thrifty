locals {
  rds_db_instances_log_running_query = <<-EOQ
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

trigger "query" "detect_and_respond_to_rds_db_instances_log_running" {
  title       = "Detect and respond to long running RDS DB instances"
  description = "Detects long running RDS DB instances and responds with your chosen action."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = local.rds_db_instances_log_running_query

  capture "insert" {
    pipeline = pipeline.respond_to_rds_db_instances_log_running
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_rds_db_instances_log_running" {
  title       = "Detect and respond to long running RDS DB instances"
  description = "Detects long running RDS DB instances and responds with your chosen action."

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

  param "default_response_option" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.rds_db_instance_log_running_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.rds_db_instance_log_running_enabled_response_options
  }

  step "query" "detect" {
    database = param.database
    sql      = local.rds_db_instances_log_running_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_rds_db_instances_log_running
    args = {
      items                    = step.query.detect.rows
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
    }
  }
}

pipeline "respond_to_rds_db_instances_log_running" {
  title       = "Respond to long running RDS DB instances"
  description = "Responds to a collection of long running RDS DB instances."

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

  param "default_response_option" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.rds_db_instance_log_running_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.rds_db_instance_log_running_enabled_response_options
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected long running RDS DB instances ${length(param.items)}."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.db_instance_identifier => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_rds_db_instance_log_running
    args = {
      title                    = each.value.title
      db_instance_identifier   = each.value.db_instance_identifier
      region                   = each.value.region
      cred                     = each.value.cred
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
    }
  }
}

pipeline "respond_to_rds_db_instance_log_running" {
  title       = "Respond to long running RDS DB instance"
  description = "Responds to a long running RDS DB instance."

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

  param "default_response_option" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.rds_db_instance_log_running_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.rds_db_instance_log_running_enabled_response_options
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected long running RDS DB Instance ${param.title}."
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
      response_options = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.StyleInfo
          pipeline_ref = local.approval_pipeline_skipped_action_notification
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