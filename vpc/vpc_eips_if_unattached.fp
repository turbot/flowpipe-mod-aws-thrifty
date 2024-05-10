locals {
  vpc_eips_if_unattached_query = <<-EOQ
  select
    concat(allocation_id, ' [', public_ip, '/', region, '/', account_id, ']') as title,
    allocation_id,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_vpc_eip
  where
    association_id is null;
  EOQ
}

trigger "query" "detect_and_correct_vpc_eips_if_unattached" {
  title         = "Detect & correct VPC EIPs if unattached"
  description   = "Detects unattached EIPs (Elastic IP addresses) and runs your chosen action."
  // documentation = file("./vpc/docs/detect_and_correct_vpc_eips_if_unattached_trigger.md")
  // tags          = merge(local.vpc_common_tags, { class = "unused" })

  enabled  = var.vpc_eips_if_unattached_trigger_enabled
  schedule = var.vpc_eips_if_unattached_trigger_schedule
  database = var.database
  sql      = local.vpc_eips_if_unattached_query

  capture "insert" {
    pipeline = pipeline.correct_vpc_eips_if_unattached
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_vpc_eips_if_unattached" {
  title         = "Detect & correct VPC EIPs if unattached"
  description   = "Detects unattached EIPs (Elastic IP addresses) and runs your chosen action."
  documentation = file("./vpc/docs/detect_and_correct_vpc_eips_if_unattached.md")
  tags          = merge(local.vpc_common_tags, { class = "unused" })

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
    default     = var.vpc_eips_if_unattached_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.vpc_eips_if_unattached_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.vpc_eips_if_unattached_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_vpc_eips_if_unattached
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

pipeline "correct_vpc_eips_if_unattached" {
  title         = "Correct VPC EIPs if unattached"
  description   = "Runs corrective action on a collection of EIPs (Elastic IP addresses) which are unattached."
  documentation = file("./vpc/docs/correct_vpc_eips_if_unattached.md")
  tags          = merge(local.vpc_common_tags, { class = "unused" })

  param "items" {
    type = list(object({
      title         = string
      allocation_id = string
      region        = string
      cred          = string
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
    default     = var.vpc_eips_if_unattached_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.vpc_eips_if_unattached_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} elastic IP addresses unattached."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.allocation_id => row }

    output "debug" {
      value = param.approvers
    }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_vpc_eip_if_unattached
    args = {
      title              = each.value.title
      allocation_id      = each.value.allocation_id
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

pipeline "correct_one_vpc_eip_if_unattached" {
  title         = "Correct one VPC EIP if unattached"
  description   = "Runs corrective action on one EIP (Elastic IP addresses) which is unattached."
  documentation = file("./vpc/docs/correct_one_vpc_eip_if_unattached.md")
  tags          = merge(local.vpc_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "allocation_id" {
    type        = string
    description = "The ID representing the allocation of the address for use with EC2-VPC."
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
    default     = var.vpc_eips_if_unattached_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.vpc_eips_if_unattached_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected elastic IP address ${param.title} unattached."
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
      actions = {
        "skip" = {
          label         = "Skip"
          value         = "skip"
          style         = local.style_info
          pipeline_ref  = local.pipeline_optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.level_verbose
            text     = "Skipped elastic IP address ${param.title} unattached."
          }
          success_msg = ""
          error_msg   = ""
        },
        "release" = {
          label         = "Release"
          value         = "release"
          style         = local.style_ok
          pipeline_ref  = local.aws_pipeline_release_eip
          pipeline_args = {
            allocation_id = param.allocation_id
            region        = param.region
            cred          = param.cred
          }
          success_msg = "Released elastic IP address ${param.title}."
          error_msg   = "Error releasing elastic IP address ${param.title}."
        }
      }
    }
  }
}

variable "vpc_eips_if_unattached_trigger_enabled" {
  type    = bool
  default = false
}

variable "vpc_eips_if_unattached_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "vpc_eips_if_unattached_default_action" {
  type        = string
  description = "The default response to use when elastic IP addresses are unattached."
  default     = "notify"
}

variable "vpc_eips_if_unattached_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "release"]
}