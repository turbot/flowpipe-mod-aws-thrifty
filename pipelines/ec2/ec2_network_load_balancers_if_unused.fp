locals {
  ec2_network_load_balancers_if_unused_query = <<-EOQ
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
      a.arn,
      a.region,
      a.sp_connection_name as conn
    from
      aws_ec2_network_load_balancer a
      left join target_resource b on a.arn = b.load_balancer_arn
    where
      jsonb_array_length(b.target_health_descriptions) = 0
  EOQ

  ec2_network_load_balancers_if_unused_default_action_enum  = ["notify", "skip", "delete_load_balancer"]
  ec2_network_load_balancers_if_unused_enabled_actions_enum = ["skip", "delete_load_balancer"]
}

variable "ec2_network_load_balancers_if_unused_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/EC2"
  }
}

variable "ec2_network_load_balancers_if_unused_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/EC2"
  }
}

variable "ec2_network_load_balancers_if_unused_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "delete_load_balancer"]
  tags = {
    folder = "Advanced/EC2"
  }
}

variable "ec2_network_load_balancers_if_unused_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_load_balancer"]
  enum        = ["skip", "delete_load_balancer"]
  tags = {
    folder = "Advanced/EC2"
  }
}

trigger "query" "detect_and_correct_ec2_network_load_balancers_if_unused" {
  title         = "Detect & correct EC2 network load balancers if unused"
  description   = "Detects EC2 network load balancers that are unused (not serving any targets) and runs your chosen action."
  documentation = file("./pipelines/ec2/docs/detect_and_correct_ec2_network_load_balancers_if_unused_trigger.md")
  tags          = merge(local.ec2_common_tags, { class = "unused" })

  enabled  = var.ec2_network_load_balancers_if_unused_trigger_enabled
  schedule = var.ec2_network_load_balancers_if_unused_trigger_schedule
  database = var.database
  sql      = local.ec2_network_load_balancers_if_unused_query

  capture "insert" {
    pipeline = pipeline.correct_ec2_network_load_balancers_if_unused
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ec2_network_load_balancers_if_unused" {
  title         = "Detect & correct EC2 network load balancers if unused"
  description   = "Detects EC2 network load balancers that are unused (not serving any targets) and runs your chosen action."
  documentation = file("./pipelines/ec2/docs/detect_and_correct_ec2_network_load_balancers_if_unused.md")
  tags          = merge(local.ec2_common_tags, { class = "unused", recommended = "true" })

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
    enum        = local.notification_level_enum
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ec2_network_load_balancers_if_unused_default_action
    enum        = local.ec2_network_load_balancers_if_unused_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_network_load_balancers_if_unused_enabled_actions
    enum        = local.ec2_network_load_balancers_if_unused_enabled_actions_enum
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ec2_network_load_balancers_if_unused_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ec2_network_load_balancers_if_unused
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

pipeline "correct_ec2_network_load_balancers_if_unused" {
  title         = "Correct EC2 network load balancers if unused"
  description   = "Runs corrective action on a collection of EC2 network load balancers that are unused (not serving any targets)."
  documentation = file("./pipelines/ec2/docs/correct_ec2_network_load_balancers_if_unused.md")
  tags          = merge(local.ec2_common_tags, { class = "unused", folder = "Internal" })

  param "items" {
    type = list(object({
      title  = string
      arn    = string
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
    enum        = local.notification_level_enum
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ec2_network_load_balancers_if_unused_default_action
    enum        = local.ec2_network_load_balancers_if_unused_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_network_load_balancers_if_unused_enabled_actions
    enum        = local.ec2_network_load_balancers_if_unused_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected ${length(param.items)} EC2 network load balancers unused (not serving any targets)."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.arn => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ec2_network_load_balancer_if_unused
    args = {
      title              = each.value.title
      arn                = each.value.arn
      region             = each.value.region
      conn               = connection.aws[each.value.conn]
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_one_ec2_network_load_balancer_if_unused" {
  title         = "Correct one EC2 network load balancer if unused"
  description   = "Runs corrective action on an EC2 network load balancer that is unused (not serving any targets)."
  documentation = file("./pipelines/ec2/docs/correct_one_ec2_network_load_balancer_if_unused.md")
  tags          = merge(local.ec2_common_tags, { class = "unused", folder = "Internal" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "arn" {
    type        = string
    description = "The ARN of the EC2 network load balancer."
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
    enum        = local.notification_level_enum
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ec2_network_load_balancers_if_unused_default_action
    enum        = local.ec2_network_load_balancers_if_unused_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_network_load_balancers_if_unused_enabled_actions
    enum        = local.ec2_network_load_balancers_if_unused_enabled_actions_enum
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected EC2 network load balancer ${param.title} unused (not serving any targets)."
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
      actions = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.style_info
          pipeline_ref = detect_correct.pipeline.optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.level_verbose
            text     = "Skipped EC2 network load balancer ${param.title} unused (not serving any targets)."
          }
          success_msg = "Skipped EC2 network load balancer ${param.title} unused (not serving any targets)."
          error_msg   = "Error skipping EC2 network load balancer ${param.title} unused (not serving any targets)."
        },
        "delete_load_balancer" = {
          label        = "Delete Load Balancer"
          value        = "delete_load_balancer"
          style        = local.style_alert
          pipeline_ref = aws.pipeline.delete_elbv2_load_balancer
          pipeline_args = {
            load_balancer_arn = param.arn
            region            = param.region
            conn              = param.conn
          }
          success_msg = "Deleted EC2 network load balancer ${param.title}."
          error_msg   = "Error deleting EC2 network load balancer ${param.title}."
        }
      }
    }
  }
}