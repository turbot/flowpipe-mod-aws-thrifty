locals {
  ec2_classic_load_balancers_if_unused_query = <<-EOQ
    select
      concat(name, ' [', region, '/', account_id, ']') as title,
      name,
      region,
      sp_connection_name as conn
    from
      aws_ec2_classic_load_balancer
    where
      jsonb_array_length(instances) <= 0
  EOQ

  ec2_classic_load_balancers_if_unused_default_action_enum = ["notify", "skip", "delete_load_balancer"]
  ec2_classic_load_balancers_if_unused_enabled_actions_enum = ["skip", "delete_load_balancer"]
}

variable "ec2_classic_load_balancers_if_unused_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/EC2"
  }
}

variable "ec2_classic_load_balancers_if_unused_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/EC2"
  }
}

variable "ec2_classic_load_balancers_if_unused_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "delete_load_balancer"]
  tags = {
    folder = "Advanced/EC2"
  }
}

variable "ec2_classic_load_balancers_if_unused_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_load_balancer"]
  enum        = ["skip", "delete_load_balancer"]
  tags = {
    folder = "Advanced/EC2"
  }
}

trigger "query" "detect_and_correct_ec2_classic_load_balancers_if_unused" {
  title         = "Detect & correct EC2 classic load balancers if unused"
  description   = "Detects unused EC2 classic load balancers and runs your chosen action."
  documentation = file("./pipelines/ec2/docs/detect_and_correct_ec2_classic_load_balancers_if_unused_trigger.md")
  tags          = merge(local.ec2_common_tags, { class = "unused" })

  enabled  = var.ec2_classic_load_balancers_if_unused_trigger_enabled
  schedule = var.ec2_classic_load_balancers_if_unused_trigger_schedule
  database = var.database
  sql      = local.ec2_classic_load_balancers_if_unused_query

  capture "insert" {
    pipeline = pipeline.correct_ec2_classic_load_balancers_if_unused
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ec2_classic_load_balancers_if_unused" {
  title         = "Detect & correct EC2 classic load balancers if unused"
  description   = "Detects unused EC2 classic load balancers and runs your chosen action."
  documentation = file("./pipelines/ec2/docs/detect_and_correct_ec2_classic_load_balancers_if_unused.md")
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
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ec2_classic_load_balancers_if_unused_default_action
    enum        = local.ec2_classic_load_balancers_if_unused_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_classic_load_balancers_if_unused_enabled_actions
    enum        = local.ec2_classic_load_balancers_if_unused_enabled_actions_enum
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ec2_classic_load_balancers_if_unused_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ec2_classic_load_balancers_if_unused
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

pipeline "correct_ec2_classic_load_balancers_if_unused" {
  title         = "Correct EC2 classic load balancers if unused"
  description   = "Executes corrective actions on EC2 classic load balancers if unused."
  documentation = file("./pipelines/ec2/docs/correct_ec2_classic_load_balancers_if_unused.md")
  tags          = merge(local.ec2_common_tags, { class = "unused", folder = "Internal" })

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
    default     = var.ec2_classic_load_balancers_if_unused_default_action
    enum        = local.ec2_classic_load_balancers_if_unused_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_classic_load_balancers_if_unused_enabled_actions
    enum        = local.ec2_classic_load_balancers_if_unused_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == "verbose"
    notifier = param.notifier
    text     = "Detected ${length(param.items)} unused EC2 classic load balancers."
  }

  step "pipeline" "correct_item" {
    for_each        = { for item in param.items : item.name => item }
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ec2_classic_load_balancer_if_unused
    args = {
      title              = each.value.title
      name               = each.value.name
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

pipeline "correct_one_ec2_classic_load_balancer_if_unused" {
  title         = "Correct one EC2 classic load balancer if unused"
  description   = "Runs corrective action on a single EC2 classic load balancer if unused."
  documentation = file("./pipelines/ec2/docs/correct_one_ec2_classic_load_balancer_if_unused.md")
  tags          = merge(local.ec2_common_tags, { class = "unused", folder = "Internal" })

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
    default     = var.ec2_classic_load_balancers_if_unused_default_action
    enum        = local.ec2_classic_load_balancers_if_unused_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_classic_load_balancers_if_unused_enabled_actions
    enum        = local.ec2_classic_load_balancers_if_unused_enabled_actions_enum
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected unused EC2 classic load balancer ${param.title}."
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
            send     = param.notification_level == "verbose"
            text     = "Skipped unused EC2 classic load balancer ${param.title}."
          }
          success_msg = "Skipped unused EC2 classic load balancer ${param.title}."
          error_msg   = "Error skipping EC2 classic load balancer ${param.title}."
        },
        "delete_load_balancer" = {
          label        = "Delete Load Balancer"
          value        = "delete_load_balancer"
          style        = local.style_alert
          pipeline_ref = aws.pipeline.delete_elb_load_balancer
          pipeline_args = {
            load_balancer_name = param.name
            region             = param.region
            conn               = param.conn
          }
          success_msg = "Deleted EC2 classic load balancer ${param.title}."
          error_msg   = "Error deleting EC2 classic load balancer ${param.title}."
        }
      }
    }
  }
}
