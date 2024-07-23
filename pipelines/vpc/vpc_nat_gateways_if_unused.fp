locals {
  vpc_nat_gateways_if_unused_query = <<-EOQ
select
  concat(nat.nat_gateway_id, ' [', nat.region, '/', nat.account_id, ']') as title,
  nat.nat_gateway_id,
  nat.region,
  nat._ctx ->> 'connection_name' as cred
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
  nat._ctx ->> 'connection_name'
having
  sum(coalesce(dest.average, 0)) = 0;
  EOQ
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
  tags          = merge(local.vpc_common_tags, { class = "unused", type = "featured" })

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
    default     = var.vpc_nat_gateways_if_unused_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.vpc_nat_gateways_if_unused_enabled_actions
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
  tags          = merge(local.vpc_common_tags, { class = "unused" })

  param "items" {
    type = list(object({
      title          = string
      nat_gateway_id = string
      region         = string
      cred           = string
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
    default     = var.vpc_nat_gateways_if_unused_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.vpc_nat_gateways_if_unused_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
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
      cred               = each.value.cred
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
  tags          = merge(local.vpc_common_tags, { class = "unused" })

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
    default     = var.vpc_nat_gateways_if_unused_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.vpc_nat_gateways_if_unused_enabled_actions
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
          pipeline_ref = local.pipeline_optional_message
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
          pipeline_ref = local.aws_pipeline_delete_nat_gateway
          pipeline_args = {
            nat_gateway_id = param.nat_gateway_id
            region         = param.region
            cred           = param.cred
          }
          success_msg = "Deleted NAT Gateway ${param.title}."
          error_msg   = "Error deleting NAT Gateway ${param.title}."
        }
      }
    }
  }
}

variable "vpc_nat_gateways_if_unused_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
}

variable "vpc_nat_gateways_if_unused_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
}

variable "vpc_nat_gateways_if_unused_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
}

variable "vpc_nat_gateways_if_unused_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete"]
}