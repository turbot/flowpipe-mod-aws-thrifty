locals {
  ec2_network_load_balancers_unused_query = <<-EOQ
    with target_resource as (
      select
        load_balancer_arn,
        target_health_descriptions,
        target_type
      from
        aws_ec2_target_group,
        jsonb_array_elements_text(load_balancer_arns) as load_balancer_arn
    )
    select
      concat(a.name, ' [', a.region, '/', a.account_id, ']') as title,
      a.name,
      a.arn,
      a.region,
      a._ctx ->> 'connection_name' as cred
    from
      aws_ec2_network_load_balancer a
      left join target_resource b on a.arn = b.load_balancer_arn
    where
      jsonb_array_length(b.target_health_descriptions) = 0
  EOQ
}

trigger "query" "detect_and_correct_ec2_network_load_balancers_unused" {
  title       = "Detect & correct unused EC2 network load balancers"
  description = "Detects EC2 network load balancers that are unused."

  enabled  = var.ec2_network_load_balancer_unused_trigger_enabled
  schedule = var.ec2_network_load_balancer_unused_trigger_schedule
  database = var.database
  sql      = local.ec2_network_load_balancers_unused_query

  capture "insert" {
    pipeline = pipeline.correct_ec2_network_load_balancers_unused
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ec2_network_load_balancers_unused" {
  title         = "Detect & correct EC2 unused network load balancers"
  description   = "Detects unused EC2 network load balancers and runs your chosen action."
  // tags          = merge(local.ec2_common_tags, {
  //   class = "unused" 
  // })

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
    default     = var.ec2_instance_age_max_days_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_instance_age_max_days_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ec2_network_load_balancers_unused_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ec2_network_load_balancers_unused
    args     = {
      items            = step.query.detect.rows
      notifier         = param.notifier
      notification_level   = param.notification_level
      approvers        = param.approvers
      default_action           = param.default_action
      enabled_actions        = param.enabled_actions
    }
  }
}

pipeline "correct_ec2_network_load_balancers_unused" {
  title         = "Corrects unused EC2 network load balancers"
  description   = "Runs corrective action on a collection of unused EC2 network load balancers."
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
    default     = var.ec2_network_load_balancer_unused_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_network_load_balancer_unused_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} unused EC2 network load balancers."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.name => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ec2_network_load_balancer_unused
    args            = {
      title                     = each.value.title
      arn                       = each.value.arn
      name                      = each.value.name
      region                    = each.value.region
      cred                      = each.value.cred
      notifier                  = param.notifier
      notification_level        = param.notification_level
      approvers                 = param.approvers
      default_action   = param.default_action
      enabled_actions  = param.enabled_actions
    }
  }
}

pipeline "correct_one_ec2_network_load_balancer_unused" {
  title         = "Correct one unused EC2 network load balancer"
  description   = "Runs corrective action on an unused EC2 network load balance."
  // tags          = merge(local.ec2_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "name" {
    type        = string
    description = "The name of the EC2 network load balancer."
  }

  param "arn" {
    type        = string
    description = "The ARN of the EC2 network load balancer."
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
    default     = var.ec2_network_load_balancer_unused_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_network_load_balancer_unused_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args     = {
      notifier         = param.notifier
      notification_level   = param.notification_level
      approvers        = param.approvers
      detect_msg       = "Detected unused EC2 Network Load Balancer ${param.title}."
      default_action           = param.default_action
      enabled_actions        = param.enabled_actions
      actions = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.style_info
          pipeline_ref  = local.pipeline_optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.level_verbose
            text     = "Skipped unused EC2 Network Load Balancer ${param.title}."
          }
          success_msg = "Skipped EC2 Network Load Balancer ${param.title}."
          error_msg   = "Error skipping EC2 Network Load Balancer ${param.title}."
        },
        "delete_network_load_balancer" = {
          label  = "Delete Network Load Balancer"
          value  = "delete_network_load_balancer"
          style  = local.style_alert
          // pipeline_ref  = local.aws_pipeline_delete_ec2_network_load_balancer // TODO: update it when you develop the pipeline
          pipeline_ref = pipeline.mock_aws_lib_delete_network_load_balancer
          pipeline_args = {
            load_balancer_arn = [param.arn]
            region            = param.region
            cred              = param.cred
          }
          success_msg = "Deleted EC2 Network Load Balancer ${param.title}."
          error_msg   = "Error deleting EC2 Network Load Balancer ${param.title}."
        }
      }
    }
  }
}

pipeline "mock_aws_lib_delete_network_load_balancer" {
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
    value = "Mocked: aws.pipeline.mock_aws_lib_delete_network_load_balancer ${param.load_balancer_arn} [${param.region}/${param.account_id}]."
  }
}