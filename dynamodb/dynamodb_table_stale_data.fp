locals {

  dynamodb_table_stale_data_query = <<-EOQ
  select
    concat(name, ' [', region, '/', account_id, ']') as title,
    name,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_dynamodb_table
  where
    (current_timestamp - (${var.dynamodb_table_stale_data_max_days}::int || ' days')::interval) > (latest_stream_label::timestamptz)
  EOQ
}

trigger "query" "detect_and_correct_dynamodb_table_stale_data_exceeding_max_age" {
  title         = "Detect & correct DynamoDB table stale data exceeding max age"
  description   = "Detects DynamoDB tables stale data  exceeding max age and runs your chosen action."
  documentation = file("./dynamodb/docs/detect_and_correct_dynamodb_table_stale_data_exceeding_max_age_trigger.md")
  tags          = merge(local.dynamodb_common_tags, { class = "unused" })

  enabled  = var.dynamodb_table_stale_data_exceeding_max_age_trigger_enabled
  schedule = var.dynamodb_table_stale_data_exceeding_max_age_trigger_schedule
  database = var.database
  sql      = local.dynamodb_table_stale_data_query

  capture "insert" {
    pipeline = pipeline.correct_dynamodb_table_stale_data_exceeding_max_age
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_dynamodb_table_stale_data_exceeding_max_age" {
  title         = "Detect & correct DynamoDB tables stale data exceeding max age"
  description   = "Detects DynamoDB tables stale data exceeding max age and runs your chosen action."
  documentation = file("./dynamodb/docs/detect_and_correct_dynamodb_table_stale_data_exceeding_max_age.md")
  tags          = merge(local.dynamodb_common_tags, { class = "unused", type = "featured" })

  param "database" {
    type        = string
    description = local.description_database
    default     = var.database
  }

  param "notifier" {
    type        = string
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(string)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.dynamodb_table_stale_data_exceeding_max_age_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.dynamodb_table_stale_data_exceeding_max_age_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.dynamodb_table_stale_data_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_dynamodb_table_stale_data_exceeding_max_age
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

pipeline "correct_dynamodb_table_stale_data_exceeding_max_age" {
  title         = "Correct DynamoDB table stale data exceeding max age"
  description   = "Runs corrective action on a collection of DynamoDB table stale data exceeding max age."
  documentation = file("./dynamodb/docs/correct_dynamodb_table_stale_data_exceeding_max_age.md")
  tags          = merge(local.dynamodb_common_tags, { class = "unused" })

  param "items" {
    type = list(object({
      title       = string
      name        = string
      region      = string
      cred        = string
    }))
    description = local.description_items
  }

  param "notifier" {
    type        = string
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(string)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.dynamodb_table_stale_data_exceeding_max_age_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.dynamodb_table_stale_data_exceeding_max_age_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} DynamoDB table stale data exceeding maximum age."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.name => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_dynamodb_table_stale_data_exceeding_max_age
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

pipeline "correct_one_dynamodb_table_stale_data_exceeding_max_age" {
  title         = "Correct one DynamoDB table stale data exceeding max age"
  description   = "Runs corrective action on an DynamoDB table stale data exceeding max age."
  // documentation = file("./dynamodb/docs/correct_one_dynamodb_table_stale_data_exceeding_max_age.md")
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

  param "cred" {
    type        = string
    description = local.description_credential
  }

  param "notifier" {
    type        = string
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(string)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.dynamodb_table_stale_data_exceeding_max_age_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.dynamodb_table_stale_data_exceeding_max_age_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected Dynamodb table stale data  ${param.title} exceeding maximum age."
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
            text     = "Skipped Dynamodb table ${param.title} exceeding maximum age."
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
            table_name  = param.name
            region      = param.region
            cred        = param.cred
          }
          success_msg = "Deleted Dynamodb table ${param.title}."
          error_msg   = "Error deleting Dynamodb table ${param.title}."
        }
      }
    }
  }
}

variable "dynamodb_table_stale_data_exceeding_max_age_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
}

variable "dynamodb_table_stale_data_exceeding_max_age_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
}

variable "dynamodb_table_stale_data_exceeding_max_age_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
}

variable "dynamodb_table_stale_data_exceeding_max_age_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_table"]
}

variable "dynamodb_table_stale_data_max_days" {
  type        = number
  description = "The maximum number of days DynamoDB table stale data can be retained."
  default     = 90
}