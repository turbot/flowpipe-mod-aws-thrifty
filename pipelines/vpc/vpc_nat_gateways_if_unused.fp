locals {
  vpc_nat_gateways_if_unused_query = <<-EOQ
    select
      concat(nat.nat_gateway_id, ' [', nat.region, '/', nat.account_id, ']') as title,
      nat.nat_gateway_id,
      nat.region,
      nat.sp_connection_name as conn
    from
      aws_vpc_nat_gateway as nat
    left join
      aws_vpc_nat_gateway_metric_bytes_out_to_destination as dest
    on
      nat.nat_gateway_id = dest.nat_gateway_id
    where
      nat.state = 'available'
    group by
      nat.nat_gateway_id,
      nat.region,
      nat.account_id,
      nat.sp_connection_name ->> 'connection_name'
    having
      sum(coalesce(dest.average, 0)) = 0;
  EOQ

  vpc_nat_gateways_if_unused_default_action_enum  = ["notify", "skip", "delete"]
  vpc_nat_gateways_if_unused_enabled_actions_enum = ["skip", "delete"]
}

variable "vpc_nat_gateways_if_unused_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/VPC"
  }
}

variable "vpc_nat_gateways_if_unused_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/VPC"
  }
}

variable "vpc_nat_gateways_if_unused_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "delete"]
  tags = {
    folder = "Advanced/VPC"
  }
}

variable "vpc_nat_gateways_if_unused_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete"]
  enum        = ["skip", "delete"]
  tags = {
    folder = "Advanced/VPC"
  }
}

trigger "query" "detect_and_correct_vpc_nat_gateways_if_unused" {
  title         = "Detect & correct VPC NAT gateways if unused"
  description   = "Detects unused NAT gateways and runs your chosen action."
  documentation = file("./pipelines/vpc/docs/detect_and_correct_vpc_nat_gateways_if_unused_trigger.md")
  tags          = merge(local.vpc_common_tags, { class = "unused" })

  enabled  = var.vpc_nat_gateways_if_unused_trigger_enabled
  schedule = var.vpc_nat_gateways_if_unused_trigger_schedule
  database = var.database
  sql      = local.vpc_nat_gateways_if_unused_query

  capture "insert" {
    pipeline = pipeline.correct_vpc_nat_gateways_if_unused
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_vpc_nat_gateways_if_unused" {
  title         = "Detect & correct VPC NAT gateways if unused"
  description   = "Detects unused NAT gateways and runs your chosen action."
  documentation = file("./pipelines/vpc/docs/detect_and_correct_vpc_nat_gateways_if_unused.md")
  tags          = merge(local.vpc_common_tags, { class = "unused", recommended = "true" })

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
    default     = var.vpc_nat_gateways_if_unused_default_action
    enum        = local.vpc_nat_gateways_if_unused_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.vpc_nat_gateways_if_unused_enabled_actions
    enum        = local.vpc_nat_gateways_if_unused_enabled_actions_enum
  }

  step "query" "detect" {
    database = param.database
    sql      = local.vpc_nat_gateways_if_unused_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_vpc_nat_gateways_if_unused
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

pipeline "correct_vpc_nat_gateways_if_unused" {
  title         = "Correct VPC NAT gateways if unused"
  description   = "Runs corrective action on a collection of NAT Gateways which are unused."
  documentation = file("./pipelines/vpc/docs/correct_vpc_nat_gateways_if_unused.md")
  tags          = merge(local.vpc_common_tags, { class = "unused", folder = "Internal" })

  param "items" {
    type = list(object({
      title          = string
      nat_gateway_id = string
      region         = string
      conn           = string
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
    default     = var.vpc_nat_gateways_if_unused_default_action
    enum        = local.vpc_nat_gateways_if_unused_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.vpc_nat_gateways_if_unused_enabled_actions
    enum        = local.vpc_nat_gateways_if_unused_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected ${length(param.items)} unused NAT Gateways."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.nat_gateway_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_vpc_nat_gateway_if_unused
    args = {
      title              = each.value.title
      nat_gateway_id     = each.value.nat_gateway_id
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

pipeline "correct_one_vpc_nat_gateway_if_unused" {
  title         = "Correct one VPC NAT gateway if unused"
  description   = "Runs corrective action on an unused NAT Gateway."
  documentation = file("./pipelines/vpc/docs/correct_one_vpc_nat_gateway_if_unused.md")
  tags          = merge(local.vpc_common_tags, { class = "unused", folder = "Internal" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "nat_gateway_id" {
    type        = string
    description = "The ID representing the NAT Gateway in the VPC."
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
    default     = var.vpc_nat_gateways_if_unused_default_action
    enum        = local.vpc_nat_gateways_if_unused_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.vpc_nat_gateways_if_unused_enabled_actions
    enum        = local.vpc_nat_gateways_if_unused_enabled_actions_enum
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected unused NAT Gateway ${param.title}."
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
            text     = "Skipped unused NAT Gateway ${param.title}."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete" = {
          label        = "Delete"
          value        = "delete"
          style        = local.style_alert
          pipeline_ref = aws.pipeline.delete_nat_gateway
          pipeline_args = {
            nat_gateway_id = param.nat_gateway_id
            region         = param.region
            conn           = param.conn
          }
          success_msg = "Deleted NAT Gateway ${param.title}."
          error_msg   = "Error deleting NAT Gateway ${param.title}."
        }
      }
    }
  }
}
