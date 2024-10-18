locals {
  rds_db_instances_exceeding_max_age_query = <<-EOQ
  select
    concat(db_instance_identifier, ' [', region, '/', account_id, ']') as title,
    db_instance_identifier,
    region,
    sp_connection_name as conn
  from
    aws_rds_db_instance
  where
    (current_timestamp - (${var.rds_db_instances_exceeding_max_age_days}::int || ' days')::interval) > create_time
  EOQ

  rds_db_instances_exceeding_max_age_default_action_enum  = ["notify", "skip", "delete_instance"]
  rds_db_instances_exceeding_max_age_enabled_actions_enum = ["skip", "delete_instance"]
}

variable "rds_db_instances_exceeding_max_age_days" {
  type        = number
  description = "The maximum number of days DB instances are allowed to run."
  default     = 90
  tags = {
    folder = "Advanced/RDS"
  }
}

variable "rds_db_instances_exceeding_max_age_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/RDS"
  }
}

variable "rds_db_instances_exceeding_max_age_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/RDS"
  }
}

variable "rds_db_instances_exceeding_max_age_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "delete_instance"]
  tags = {
    folder = "Advanced/RDS"
  }
}

variable "rds_db_instances_exceeding_max_age_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_instance"]
  enum        = ["skip", "delete_instance"]
  tags = {
    folder = "Advanced/RDS"
  }
}

trigger "query" "detect_and_correct_rds_db_instances_exceeding_max_age" {
  title         = "Detect & correct RDS DB instances exceeding max age"
  description   = "Detects long running RDS DB instances and runs your chosen action."
  documentation = file("./pipelines/rds/docs/detect_and_correct_rds_db_instances_exceeding_max_age_trigger.md")
  tags          = merge(local.rds_common_tags, { class = "managed" })

  enabled  = var.rds_db_instances_exceeding_max_age_trigger_enabled
  schedule = var.rds_db_instances_exceeding_max_age_trigger_schedule
  database = var.database
  sql      = local.rds_db_instances_exceeding_max_age_query

  capture "insert" {
    pipeline = pipeline.correct_rds_db_instances_exceeding_max_age
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_rds_db_instances_exceeding_max_age" {
  title         = "Detect & correct RDS DB instances exceeding max age"
  description   = "Detects long running RDS DB instances and runs your chosen action."
  documentation = file("./pipelines/rds/docs/detect_and_correct_rds_db_instances_exceeding_max_age.md")
  tags          = merge(local.rds_common_tags, { class = "managed", recommended = "true" })

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
    default     = var.rds_db_instances_exceeding_max_age_default_action
    enum        = local.rds_db_instances_exceeding_max_age_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.rds_db_instances_exceeding_max_age_enabled_actions
    enum        = local.rds_db_instances_exceeding_max_age_enabled_actions_enum
  }

  step "query" "detect" {
    database = param.database
    sql      = local.rds_db_instances_exceeding_max_age_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_rds_db_instances_exceeding_max_age
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

pipeline "correct_rds_db_instances_exceeding_max_age" {
  title         = "Correct RDS DB instances exceeding max age"
  description   = "Runs corrective action on a collection of long running RDS DB instances."
  documentation = file("./pipelines/rds/docs/correct_rds_db_instances_exceeding_max_age.md")
  tags          = merge(local.rds_common_tags, { class = "managed", folder = "Internal" })

  param "items" {
    type = list(object({
      title                  = string
      db_instance_identifier = string
      region                 = string
      conn                   = string
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
    default     = var.rds_db_instances_exceeding_max_age_default_action
    enum        = local.rds_db_instances_exceeding_max_age_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.rds_db_instances_exceeding_max_age_enabled_actions
    enum        = local.rds_db_instances_exceeding_max_age_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected long running RDS DB instances ${length(param.items)}."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.db_instance_identifier => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_rds_db_instance_exceeding_max_age
    args = {
      title                  = each.value.title
      db_instance_identifier = each.value.db_instance_identifier
      region                 = each.value.region
      conn                   = connection.aws[each.value.conn]
      notifier               = param.notifier
      notification_level     = param.notification_level
      approvers              = param.approvers
      default_action         = param.default_action
      enabled_actions        = param.enabled_actions
    }
  }
}

pipeline "correct_one_rds_db_instance_exceeding_max_age" {
  title         = "Correct one RDS DB instance exceeding max age"
  description   = "Runs corrective action on a long running RDS DB instance."
  documentation = file("./pipelines/rds/docs/correct_one_rds_db_instance_exceeding_max_age.md")
  tags          = merge(local.rds_common_tags, { class = "managed", folder = "Internal" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "db_instance_identifier" {
    type        = string
    description = "The identifier of DB instance."
  }

  param "region" {
    type        = string
    description = local.description_region
  }

  param "conn" {
    type        = connection.aws
    description = local.description_connection
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
    default     = var.rds_db_instances_exceeding_max_age_default_action
    enum        = local.rds_db_instances_exceeding_max_age_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.rds_db_instances_exceeding_max_age_enabled_actions
    enum        = local.rds_db_instances_exceeding_max_age_enabled_actions_enum
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
          style        = local.style_info
          pipeline_ref = detect_correct.pipeline.optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.level_verbose
            text     = "Skipped long running RDS DB Instance ${param.title}."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete_instance" = {
          label        = "Delete Instance"
          value        = "delete_instance"
          style        = local.style_alert
          pipeline_ref = aws.pipeline.delete_rds_db_instance
          pipeline_args = {
            db_instance_identifier = param.db_instance_identifier
            region                 = param.region
            conn                   = param.conn
          }
          success_msg = "Deleted RDS DB Instance ${param.title}."
          error_msg   = "Error deleting RDS DB Instance ${param.title}."
        }
      }
    }
  }
}
