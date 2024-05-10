locals {
  ec2_classic_load_balancers_unused_query = <<-EOQ
select
  concat(name, ' [', region, '/', account_id, ']') as title,
  name,
  region,
  _ctx ->> 'connection_name' as cred
from
  aws_ec2_classic_load_balancer
where
  jsonb_array_length(instances) <= 0
  EOQ
}


trigger "query" "detect_and_correct_ec2_classic_load_balancers_unused" {
  title       = "Detect & correct unused EC2 classic load balancers"
  description = "Detects EC2 classic load balancers that are unused."

  enabled  = var.ec2_classic_load_balancer_unused_trigger_enabled
  schedule = var.ec2_classic_load_balancer_unused_trigger_schedule
  database = var.database
  sql      = local.ec2_classic_load_balancers_unused_query

  capture "insert" {
    pipeline = pipeline.correct_ec2_classic_load_balancers_unused
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ec2_classic_load_balancers_unused" {
  title       = "Detect & correct EC2 unused classic load balancers"
  description = "Detects unused EC2 classic load balancers and runs your chosen action."
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
    sql      = local.ec2_classic_load_balancers_unused_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ec2_classic_load_balancers_unused
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

pipeline "correct_ec2_classic_load_balancers_unused" {
  title       = "Corrects unused EC2 classic load balancers"
  description = "Runs corrective action on a collection of unused EC2 classic load balancers."
  // tags          = merge(local.ec2_common_tags, {
  //   class = "deprecated"
  // })

  param "items" {
    type = list(object({
      title  = string
      name   = string
      region = string
      cred   = string
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
    default     = var.ec2_classic_load_balancer_unused_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_classic_load_balancer_unused_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} unused EC2 classic load balancers."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.name => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ec2_classic_load_balancer_unused
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

pipeline "correct_one_ec2_classic_load_balancer_unused" {
  title       = "Correct one unused EC2 classic load balancer"
  description = "Runs corrective action on an unused EC2 classic load balancer."
  // tags          = merge(local.ec2_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "name" {
    type        = string
    description = "The name of the EC2 classic load balancer."
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
    default     = var.ec2_classic_load_balancer_unused_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_classic_load_balancer_unused_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected unused EC2 Classic Load Balancer ${param.title}."
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
            text     = "Skipped unused EC2 Classic Load Balancer ${param.title}."
          }
          success_msg = "Skipped unused EC2 Classic Load Balancer ${param.title}."
          error_msg   = "Error skipping EC2 Classic Load Balancer ${param.title}."
        },
        "delete_ec2_classic_load_balancer" = {
          label        = "Delete EC2 Classic Load Balancer"
          value        = "delete_ec2_classic_load_balancer"
          style        = local.style_alert
          pipeline_ref = local.aws_pipeline_delete_elb_load_balancer
          pipeline_args = {
            load_balancer_arn = param.name
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