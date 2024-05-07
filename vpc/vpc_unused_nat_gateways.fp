locals {
  vpc_unused_nat_gateways_query = <<-EOQ
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

trigger "query" "detect_and_respond_to_vpc_unused_nat_gateways" {
  title       = "Detect and respond to unused NAT Gateways"
  description = "Detects unused NAT Gateways and responds with your chosen action."
  //tags       = merge(local.vpc_common_tags, { class = "unused" })

  enabled  = var.vpc_unused_nat_gateways_trigger_enabled
  schedule = var.vpc_unused_nat_gateways_trigger_schedule
  database = var.database
  sql      = local.vpc_unused_nat_gateways_query

  capture "insert" {
    pipeline = pipeline.respond_to_vpc_unused_nat_gateways
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_vpc_unused_nat_gateways" {
  title       = "Detect and respond to unused NAT Gateways"
  description = "Detects unused NAT Gateways and responds with your chosen action."
  // tags          = merge(local.vpc_common_tags, { class = "unused" })

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

  param "default_action" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.unused_nat_gateways_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.unused_nat_gateways_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.vpc_unused_nat_gateways_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_vpc_unused_nat_gateways
    args = {
      items                    = step.query.detect.rows
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
    }
  }
}

pipeline "respond_to_vpc_unused_nat_gateways" {
  title       = "Respond to unused NAT Gateways"
  description = "Responds to a collection of NAT Gateways which are unused."
  // documentation = file("./vpc/unused_nat_gateways.md")
  // tags          = merge(local.vpc_common_tags, { class = "unused" })

  param "items" {
    type = list(object({
      title          = string
      nat_gateway_id = string
      region         = string
      cred           = string
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

  param "default_action" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.unused_nat_gateways_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.unused_nat_gateways_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} unused NAT Gateways."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.nat_gateway_id => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_unused_nat_gateway
    args = {
      title                    = each.value.title
      nat_gateway_id           = each.value.nat_gateway_id
      region                   = each.value.region
      cred                     = each.value.cred
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
    }
  }
}

pipeline "respond_to_unused_nat_gateway" {
  title       = "Respond to unused NAT Gateway"
  description = "Responds to an unused NAT Gateway."
  // tags          = merge(local.vpc_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "nat_gateway_id" {
    type        = string
    description = "The ID representing the NAT Gateway in the VPC."
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

  param "default_action" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.unused_nat_gateways_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.unused_nat_gateways_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected unused NAT Gateway ${param.title}."
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
      actions = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.StyleInfo
          pipeline_ref = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped unused NAT Gateway ${param.title}."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete" = {
          label        = "Delete"
          value        = "delete"
          style        = local.StyleAlert
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

pipeline "mock_aws_pipeline_delete_nat_gateway" {
  param "nat_gateway_id" {
    type        = string
  }

  param "region" {
    type        = string
  }

  param "cred" {
    type        = string
  }

  output "result" {
    value = "Mocked: Delete NAT Gateway [GatewayID: ${param.nat_gateway_id}, Region: ${param.region}, Cred: ${param.cred}]"
  }
}
