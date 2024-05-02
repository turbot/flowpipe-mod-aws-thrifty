locals {
  ec2_classic_load_balancer_unused_query = <<-EOQ
    select
      concat(name, ' [', region, '/', account_id, ']') as title,
      name,
      arn,
      region,
      _ctx ->> 'connection_name' as cred
    from
      aws_ec2_classic_load_balancer
    where
      jsonb_array_length(instances) <= 0
  EOQ
}


trigger "query" "detect_and_respond_to_ec2_classic_load_balancer_unused" {
  title       = "Detect and respond to unused EC2 classic load balancers"
  description = "Detects EC2 classic load balancers that are unused."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = local.ec2_classic_load_balancer_unused_query

  capture "insert" {
    pipeline = pipeline.respond_to_ec2_classic_load_balancer_unused
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_ec2_classic_load_balancer_unused" {
  title         = "Detect and respond to EC2 unused classic load balancers"
  description   = "Detects unused EC2 classic load balancers and responds with your chosen action."
  // tags          = merge(local.ec2_common_tags, {
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
    default     = var.ec2_instance_age_max_days_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ec2_instance_age_max_days_enabled_response_options
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ec2_classic_load_balancer_unused_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_ec2_classic_load_balancers_unused
    args     = {
      items            = step.query.detect.rows
      notifier         = param.notifier
      notification_level   = param.notification_level
      approvers        = param.approvers
      default_response_option           = param. default_response_option
      enabled_response_options        = param. enabled_response_options
    }
  }
}

pipeline "respond_to_ec2_classic_load_balancers_unused" {
  title         = "Respond to unused EC2 classic load balancers"
  description   = "Responds to a collection of unused EC2 classic load balancers."
  // tags          = merge(local.ec2_common_tags, { 
  //   class = "deprecated" 
  // })

  param "items" {
    type = list(object({
      title       = string
      name        = string
      arn         = string
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
    default     = var.ec2_classic_load_balancer_unused_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ec2_classic_load_balancer_unused_enabled_response_options
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} unused EC2 classic load balancers."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.name => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_ec2_classic_load_balancer_unused
    args            = {
      title            = each.value.title
      arn              = each.value.arn
      name             = each.value.name
      region           = each.value.region
      cred             = each.value.cred
      notifier         = param.notifier
      notification_level   = param.notification_level
      approvers        = param.approvers
      default_response_option           = param. default_response_option
      enabled_response_options        = param. enabled_response_options
    }
  }
}

pipeline "respond_to_ec2_classic_load_balancer_unused" {
  title         = "Respond to unused EC2 classic load balancer"
  description   = "Responds to an unused EC2 classic load balancer."
  // tags          = merge(local.ec2_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "name" {
    type        = string
    description = "The name of the EC2 classic load balancer."
  }

  param "arn" {
    type        = string
    description = "The ARN of the EC2 classic load balancer."
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
    default     = var.ec2_classic_load_balancer_unused_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ec2_classic_load_balancer_unused_enabled_response_options
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args     = {
      notifier         = param.notifier
      notification_level   = param.notification_level
      approvers        = param.approvers
      detect_msg       = "Detected unused EC2 Classic Load Balancer ${param.title}."
      default_response_option           = param. default_response_option
      enabled_response_options        = param. enabled_response_options
      response_options = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.StyleInfo
          pipeline_ref  = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped unused EC2 Classic Load Balancer ${param.title}."
          }
          success_msg = "Skipped unused EC2 Classic Load Balancer ${param.title}."
          error_msg   = "Error skipping EC2 Classic Load Balancer ${param.title}."
        },
        "delete_ec2_classic_load_balancer" = {
          label  = "Delete EC2 Classic Load Balancer"
          value  = "delete_ec2_classic_load_balancer"
          style  = local.StyleAlert
          // pipeline_ref  = local.aws_pipeline_delete_ec2_classic_load_balancer // TODO: update it when you develop the pipeline
          pipeline_ref = pipeline.mock_aws_lib_delete_classic_load_balancer
          pipeline_args = {
            load_balancer_arn = [param.arn]
            region            = param.region
            cred              = param.cred
          }
          success_msg = "Deleted EC2 Classic Load Balancer ${param.title}."
          error_msg   = "Error deleting EC2 Classic Load Balancer ${param.title}."
        }
      }
    }
  }
}

pipeline "mock_aws_lib_delete_classic_load_balancer" {
  param "cred" {
    type = string
    default = "default"
  }

  param "load_balancer_arn" {
    type = string
  }

  param "region" {
    type = string
  }

  param "account_id" {
    type = string
  }

  output "result" {
    value = "Mocked: aws.pipeline.mock_aws_lib_delete_classic_load_balancer ${param.load_balancer_arn} [${param.region}/${param.account_id}]."
  }
}