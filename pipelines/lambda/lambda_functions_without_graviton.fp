locals {
  lambda_functions_without_graviton_query = <<-EOQ
  select
    concat(name, ' [', region, '/', account_id, ']') as title,
    name,
    region,
    sp_connection_name as conn
  from
    aws_lambda_function,
    jsonb_array_elements_text(architectures) as architecture
  where
    architecture != 'arm64';
  EOQ
}

trigger "query" "detect_and_correct_lambda_functions_without_graviton" {
  title         = "Detect & correct Lambda functions without graviton"
  description   = "Detects Lambda functions without graviton processor and runs your chosen action."
  documentation = file("./pipelines/lambda/docs/detect_and_correct_lambda_functions_without_graviton_trigger.md")
  tags          = merge(local.lambda_common_tags, { class = "deprecated" })

  enabled  = var.lambda_functions_without_graviton_trigger_enabled
  schedule = var.lambda_functions_without_graviton_trigger_schedule
  database = var.database
  sql      = local.lambda_functions_without_graviton_query

  capture "insert" {
    pipeline = pipeline.correct_lambda_functions_without_graviton
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_lambda_functions_without_graviton" {
  title         = "Detect & correct Lambda functions without graviton"
  description   = "Detects Lambda functions without graviton processor and runs your chosen action."
  documentation = file("./pipelines/lambda/docs/detect_and_correct_lambda_functions_without_graviton.md")
  tags          = merge(local.lambda_common_tags, { class = "deprecated", recommended = "true" })

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
    default     = var.lambda_functions_without_graviton_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.lambda_functions_without_graviton_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.lambda_functions_without_graviton_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_lambda_functions_without_graviton
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

pipeline "correct_lambda_functions_without_graviton" {
  title         = "Correct Lambda functions without graviton"
  description   = "Runs corrective action on a collection of Lambda functions without graviton."
  documentation = file("./pipelines/lambda/docs/correct_lambda_functions_without_graviton.md")
  tags = merge(local.lambda_common_tags, {
    class = "deprecated"
  })

  param "items" {
    type = list(object({
      title  = string
      name   = string
      region = string
      conn   = string
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
    default     = var.lambda_functions_without_graviton_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.lambda_functions_without_graviton_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected ${length(param.items)} Lambda functions without graviton."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.name => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_lambda_function_without_graviton
    args = {
      title              = each.value.title
      name               = each.value.name
      region             = each.value.region
      conn               = each.value.conn
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_one_lambda_function_without_graviton" {
  title         = "Correct one Lambda function without graviton"
  description   = "Runs corrective action on a Lambda function without graviton."
  documentation = file("./pipelines/lambda/docs/correct_one_lambda_function_without_graviton.md")
  tags          = merge(local.lambda_common_tags, { class = "deprecated" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "name" {
    type        = string
    description = "The ID of the Lambda function."
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
    default     = var.lambda_functions_without_graviton_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.lambda_functions_without_graviton_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected Lambda function ${param.title} without graviton."
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
            text     = "Skipped Lambda function ${param.title} without graviton."
          }
          success_msg = "Skipped Lambda function ${param.title}."
          error_msg   = "Error skipping Lambda function ${param.title}."
        },
        "delete_function" = {
          label        = "Delete Function"
          value        = "delete_function"
          style        = local.style_alert
          pipeline_ref = local.aws_pipeline_delete_lambda_function
          pipeline_args = {
            function_name = [param.name]
            region        = param.region
            conn          = param.conn
          }
          success_msg = "Deleted Lambda function ${param.title}."
          error_msg   = "Error deleting Lambda function ${param.title}."
        }
      }
    }
  }
}

// Variable definitions
variable "lambda_functions_without_graviton_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/Lambda"
  }
}

variable "lambda_functions_without_graviton_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/Lambda"
  }
}

variable "lambda_functions_without_graviton_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  tags = {
    folder = "Advanced/Lambda"
  }
}

variable "lambda_functions_without_graviton_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_function"]
  tags = {
    folder = "Advanced/Lambda"
  }
}
