locals {
  vpc_eips_if_unattached_query = <<-EOQ
  select
    concat(allocation_id, ' [', public_ip, '/', region, '/', account_id, ']') as title,
    allocation_id,
    region,
    sp_connection_name as conn
  from
    aws_vpc_eip
  where
    association_id is null;
  EOQ

  vpc_eips_if_unattached_default_action_enum  = ["notify", "skip", "release"]
  vpc_eips_if_unattached_enabled_actions_enum = ["skip", "release"]
}

variable "vpc_eips_if_unattached_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/VPC"
  }
}

variable "vpc_eips_if_unattached_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/VPC"
  }
}

variable "vpc_eips_if_unattached_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "release"]
  tags = {
    folder = "Advanced/VPC"
  }
}

variable "vpc_eips_if_unattached_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "release"]
  enum        = ["skip", "release"]
  tags = {
    folder = "Advanced/VPC"
  }
}

trigger "query" "detect_and_correct_vpc_eips_if_unattached" {
  title         = "Detect & correct VPC EIPs if unattached"
  description   = "Detects unattached EIPs (Elastic IP addresses) and runs your chosen action."
  documentation = file("./pipelines/vpc/docs/detect_and_correct_vpc_eips_if_unattached_trigger.md")
  tags          = merge(local.vpc_common_tags, { class = "unused" })

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
  documentation = file("./pipelines/vpc/docs/detect_and_correct_vpc_eips_if_unattached.md")
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
    default     = var.vpc_eips_if_unattached_default_action
    enum        = local.vpc_eips_if_unattached_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.vpc_eips_if_unattached_enabled_actions
    enum        = local.vpc_eips_if_unattached_enabled_actions_enum
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
  documentation = file("./pipelines/vpc/docs/correct_vpc_eips_if_unattached.md")
  tags          = merge(local.vpc_common_tags, { class = "unused", folder = "Internal" })

  param "items" {
    type = list(object({
      title         = string
      allocation_id = string
      region        = string
      conn          = string
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
    default     = var.vpc_eips_if_unattached_default_action
    enum        = local.vpc_eips_if_unattached_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.vpc_eips_if_unattached_enabled_actions
    enum        = local.vpc_eips_if_unattached_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
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
      conn               = connection.aws[each.value.conn]
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
  documentation = file("./pipelines/vpc/docs/correct_one_vpc_eip_if_unattached.md")
  tags          = merge(local.vpc_common_tags, { class = "unused", folder = "Internal" })

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
    default     = var.vpc_eips_if_unattached_default_action
    enum        = local.vpc_eips_if_unattached_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.vpc_eips_if_unattached_enabled_actions
    enum        = local.vpc_eips_if_unattached_enabled_actions_enum
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
          label        = "Skip"
          value        = "skip"
          style        = local.style_info
          pipeline_ref = detect_correct.pipeline.optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.level_verbose
            text     = "Skipped elastic IP address ${param.title} unattached."
          }
          success_msg = ""
          error_msg   = ""
        },
        "release" = {
          label        = "Release"
          value        = "release"
          style        = local.style_ok
          pipeline_ref = aws.pipeline.release_eip
          pipeline_args = {
            allocation_id = param.allocation_id
            region        = param.region
            conn          = param.conn
          }
          success_msg = "Released elastic IP address ${param.title}."
          error_msg   = "Error releasing elastic IP address ${param.title}."
        }
      }
    }
  }
}
