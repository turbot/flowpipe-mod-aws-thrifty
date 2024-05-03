locals {
  lambda_functions_without_graviton_query = <<-EOQ
  select
    concat(name, ' [', region, '/', account_id, ']') as title,
    name,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_lambda_function,
    jsonb_array_elements_text(architectures) as architecture
  where
    architecture != 'arm64';
  EOQ
}

trigger "query" "detect_and_respond_to_lambda_functions_without_graviton" {
  title       = "Detect and respond to Lambda functions without graviton processor"
  description = "Detects Lambda functions without graviton processor and responds with your chosen action."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = local.lambda_functions_without_graviton_query

  capture "insert" {
    pipeline = pipeline.respond_to_lambda_functions_without_graviton
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_lambda_functions_without_graviton" {
  title         = "Detect and respond to Lambda functions without graviton processor"
  description   = "Detects Lambda functions without graviton processor and responds with your chosen action."
  // tags          = merge(local.lambda_common_tags, {
  //   class = "unused" 
  // })

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
    default     = var.lambda_function_without_graviton_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.lambda_function_without_graviton_enabled_response_options
  }

  step "query" "detect" {
    database = param.database
    sql      = local.lambda_functions_without_graviton_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_lambda_functions_without_graviton
    args     = {
      items                     = step.query.detect.rows
      notifier                  = param.notifier
      notification_level        = param.notification_level
      approvers                 = param.approvers
      default_response_option   = param.default_response_option
      enabled_response_options  = param.enabled_response_options
    }
  }
}

pipeline "respond_to_lambda_functions_without_graviton" {
  title         = "Respond to Lambda functions without graviton processor"
  description   = "Responds to a collection of Lambda functions without graviton processor."
  // tags          = merge(local.lambda_common_tags, { 
  //   class = "deprecated" 
  // })

  param "items" {
    type = list(object({
      title       = string
      name        = string
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

  param "default_response_option" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.lambda_function_without_graviton_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.lambda_function_without_graviton_enabled_response_options
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} Lambda functions without graviton processor."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.name => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_lambda_function_without_graviton
    args            = {
      title                      = each.value.title
      name                       = each.value.name
      region                     = each.value.region
      cred                       = each.value.cred
      notifier                   = param.notifier
      notification_level         = param.notification_level
      approvers                  = param.approvers
      default_response_option    = param.default_response_option
      enabled_response_options   = param.enabled_response_options
    }
  }
}

pipeline "respond_to_lambda_function_without_graviton" {
  title         = "Respond to an Lambda function without graviton processor"
  description   = "Responds to an Lambda function without graviton processor."
  // tags          = merge(local.lambda_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "name" {
    type        = string
    description = "The ID of the Lambda function."
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
    default     = var.lambda_function_without_graviton_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.lambda_function_without_graviton_enabled_response_options
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args     = {
      notifier                  = param.notifier
      notification_level        = param.notification_level
      approvers                 = param.approvers
      detect_msg                = "Detected Lambda function ${param.title} without graviton processor."
      default_response_option   = param.default_response_option
      enabled_response_options  = param.enabled_response_options
      response_options = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.StyleInfo
          pipeline_ref  = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped Lambda Function ${param.title} without graviton processor."
          }
          success_msg = "Skipped Lambda Function ${param.title}."
          error_msg   = "Error skipping Lambda Function ${param.title}."
        },
        "delete_function" = {
          label  = "Delete Function"
          value  = "delete_function"
          style  = local.StyleAlert
          pipeline_ref  = local.aws_pipeline_delete_lambda_functions
          pipeline_args = {
            function_name = [param.name]
            region        = param.region
            cred          = param.cred
          }
          success_msg = "Deleted Lambda Function ${param.title}."
          error_msg   = "Error deleting Lambda Function ${param.title}."
        }
      }
    }
  }
}