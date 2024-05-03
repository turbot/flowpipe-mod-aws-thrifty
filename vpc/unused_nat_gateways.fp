trigger "query" "unused_nat_gateways" {
  title       = "Detect and respond to unused NAT Gateways"
  description = "Detects unused NAT Gateways and responds with your chosen action."
  //tags       = merge(local.vpc_common_tags, { class = "unused" })

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = file("./vpc/unused_nat_gateways.sql")

  capture "insert" {
    pipeline = pipeline.respond_to_unused_nat_gateways
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_unused_nat_gateways" {
  title       = "Detect and respond to unused NAT Gateways"
  description = "Detects unused NAT Gateways and responds with your chosen action."
  // documentation = file("./vpc/unused_nat_gateways.md")
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

  param "default_response_option" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.unused_nat_gateways_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.unused_nat_gateways_enabled_response_options
  }

  step "query" "detect" {
    database = param.database
    sql      = file("./vpc/unused_nat_gateways.sql")
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_unused_nat_gateways
    args = {
      items                    = step.query.detect.rows
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
    }
  }
}

pipeline "respond_to_unused_nat_gateways" {
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

  param "default_response_option" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.unused_nat_gateways_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.unused_nat_gateways_enabled_response_options
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
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
    }
  }
}

pipeline "respond_to_unused_nat_gateway" {
  title       = "Respond to unused NAT Gateway"
  description = "Responds to an unused NAT Gateway."
  // documentation = file("./vpc/unused_nat_gateways.md")
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

  param "default_response_option" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.unused_nat_gateways_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.unused_nat_gateways_enabled_response_options
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected unused NAT Gateway ${param.title}."
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
      response_options = {
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
