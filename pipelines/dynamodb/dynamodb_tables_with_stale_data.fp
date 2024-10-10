locals {

  dynamodb_tables_with_stale_data_query = <<-EOQ
  select
    concat(name, ' [', region, '/', account_id, ']') as title,
    name,
    region,
    sp_connection_name as conn
  from
    aws_dynamodb_table
  where
    (current_timestamp - (${var.dynamodb_tables_with_stale_data_max_days}::int || ' days')::interval) > (latest_stream_label::timestamp)
  EOQ
}

trigger "query" "detect_and_correct_dynamodb_tables_with_stale_data" {
  title         = "Detect & correct DynamoDB table with stale data"
  description   = "Detects DynamoDB tables with stale data and runs your chosen action."
  documentation = file("./pipelines/dynamodb/docs/detect_and_correct_dynamodb_tables_with_stale_data_trigger.md")
  tags          = merge(local.dynamodb_common_tags, { class = "unused" })

  enabled  = var.dynamodb_tables_with_stale_data_trigger_enabled
  schedule = var.dynamodb_tables_with_stale_data_trigger_schedule
  database = var.database
  sql      = local.dynamodb_tables_with_stale_data_query

  capture "insert" {
    pipeline = pipeline.correct_dynamodb_tables_with_stale_data
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_dynamodb_tables_with_stale_data" {
  title         = "Detect & correct DynamoDB tables with stale data"
  description   = "Detects DynamoDB tables with stale data and runs your chosen action."
  documentation = file("./pipelines/dynamodb/docs/detect_and_correct_dynamodb_tables_with_stale_data.md")
  tags          = merge(local.dynamodb_common_tags, { class = "unused", recommended = "true" })

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
    default     = var.dynamodb_tables_with_stale_data_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.dynamodb_tables_with_stale_data_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.dynamodb_tables_with_stale_data_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_dynamodb_tables_with_stale_data
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

pipeline "correct_dynamodb_tables_with_stale_data" {
  title         = "Correct DynamoDB table with stale data"
  description   = "Runs corrective action on a collection of DynamoDB table with stale data."
  documentation = file("./pipelines/dynamodb/docs/correct_dynamodb_tables_with_stale_data.md")
  tags          = merge(local.dynamodb_common_tags, { class = "unused" })

  param "items" {
    type = list(object({
      title  = string
      name   = string
      region = string
      cred   = string
    }))
    description = local.description_items
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
    default     = var.dynamodb_tables_with_stale_data_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.dynamodb_tables_with_stale_data_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected ${length(param.items)} DynamoDB table with stale data."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.name => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_dynamodb_table_with_stale_data
    args = {
      title              = each.value.title
      name               = each.value.name
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

pipeline "correct_one_dynamodb_table_with_stale_data" {
  title         = "Correct one DynamoDB table with stale data"
  description   = "Runs corrective action on an DynamoDB table with stale data."
  documentation = file("./pipelines/dynamodb/docs/correct_one_dynamodb_table_with_stale_data.md")
  tags          = merge(local.dynamodb_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "name" {
    type        = string
    description = "The name of the DynamoDB table."
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
    default     = var.dynamodb_tables_with_stale_data_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.dynamodb_tables_with_stale_data_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected DynamoDB table ${param.title} with stale data."
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
            text     = "Skipped DynamoDB table ${param.title} with stale data."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete_table" = {
          label        = "Delete Table"
          value        = "delete_table"
          style        = local.style_alert
          pipeline_ref = local.aws_pipeline_delete_dynamodb_table
          pipeline_args = {
            table_name = param.name
            region     = param.region
            cred       = param.cred
          }
          success_msg = "Deleted DynamoDB table ${param.title}."
          error_msg   = "Error deleting DynamoDB table ${param.title}."
        }
      }
    }
  }
}

variable "dynamodb_tables_with_stale_data_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/DynamoDB"
  }
}

variable "dynamodb_tables_with_stale_data_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/DynamoDB"
  }
}

variable "dynamodb_tables_with_stale_data_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  tags = {
    folder = "Advanced/DynamoDB"
  }
}

variable "dynamodb_tables_with_stale_data_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_table"]
  tags = {
    folder = "Advanced/DynamoDB"
  }
}

variable "dynamodb_tables_with_stale_data_max_days" {
  type        = number
  description = "The maximum number of days DynamoDB table stale data can be retained."
  default     = 90
  tags = {
    folder = "Advanced/DynamoDB"
  }
}
