locals {
  route53_health_checks_if_unused_query = <<-EOQ
  with health_check as (
    select
      r.health_check_id as health_check_id
    from
      aws_route53_zone as z,
      aws_route53_record as r
    where
      r.zone_id = z.id
  )
  select
    concat(h.id, ' [', h.region, '/', h.account_id, ']') as title,
    h.id,
    h.region,
    h.sp_connection_name as conn
  from
    aws_route53_health_check as h
  left join
    health_check as c on h.id = c.health_check_id
  where
    c.health_check_id is null
  EOQ

  route53_health_checks_if_unused_default_action_enum  = ["notify", "skip", "delete_health_check"]
  route53_health_checks_if_unused_enabled_actions_enum = ["skip", "delete_health_check"]
}

variable "route53_health_checks_if_unused_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/Route53"
  }
}

variable "route53_health_checks_if_unused_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/Route53"
  }
}

variable "route53_health_checks_if_unused_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "delete_health_check"]
  tags = {
    folder = "Advanced/Route53"
  }
}

variable "route53_health_checks_if_unused_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_health_check"]
  enum        = ["skip", "delete_health_check"]
  tags = {
    folder = "Advanced/Route53"
  }
}

trigger "query" "detect_and_correct_route53_health_checks_if_unused" {
  title         = "Detect & correct Route53 health checks if unused"
  description   = "Detects Route53 health checks that are not used by any Route53 records and runs your chosen action."
  documentation = file("./pipelines/route53/docs/detect_and_correct_route53_health_checks_if_unused_trigger.md")
  tags          = merge(local.route53_common_tags, { class = "unused" })

  enabled  = var.route53_health_checks_if_unused_trigger_enabled
  schedule = var.route53_health_checks_if_unused_trigger_schedule
  database = var.database
  sql      = local.route53_health_checks_if_unused_query

  capture "insert" {
    pipeline = pipeline.correct_route53_health_checks_if_unused
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_route53_health_checks_if_unused" {
  title         = "Detect & correct Route53 health checks if unused"
  description   = "Detects Route53 health checks that are not used by any Route53 records and runs your chosen action."
  documentation = file("./pipelines/route53/docs/detect_and_correct_route53_health_checks_if_unused.md")
  tags          = merge(local.route53_common_tags, { class = "unused", recommended = "true" })

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
    default     = var.route53_health_checks_if_unused_default_action
    enum        = local.route53_health_checks_if_unused_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.route53_health_checks_if_unused_enabled_actions
    enum        = local.route53_health_checks_if_unused_enabled_actions_enum
  }

  step "query" "detect" {
    database = param.database
    sql      = local.route53_health_checks_if_unused_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_route53_health_checks_if_unused
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

pipeline "correct_route53_health_checks_if_unused" {
  title         = "Correct Route53 health checks if unused"
  description   = "Runs corrective action on a collection of Route53 health checks that are detected as unused."
  documentation = file("./pipelines/route53/docs/correct_route53_health_checks_if_unused.md")
  tags          = merge(local.route53_common_tags, { class = "unused", folder = "Internal" })

  param "items" {
    type = list(object({
      title  = string
      id     = string
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
    default     = var.route53_health_checks_if_unused_default_action
    enum        = local.route53_health_checks_if_unused_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.route53_health_checks_if_unused_enabled_actions
    enum        = local.route53_health_checks_if_unused_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected unused Route53 health checks ${length(param.items)}."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_route53_health_check_if_unused
    args = {
      title              = each.value.title
      id                 = each.value.id
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

pipeline "correct_one_route53_health_check_if_unused" {
  title         = "Correct one Route53 health check if unused"
  description   = "Runs corrective action on an unused Route53 health check."
  documentation = file("./pipelines/route53/docs/correct_one_route53_health_check_if_unused.md")
  tags          = merge(local.route53_common_tags, { class = "unused", folder = "Internal" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "id" {
    type        = string
    description = "The ID of the health check."
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
    default     = var.route53_health_checks_if_unused_default_action
    enum        = local.route53_health_checks_if_unused_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.route53_health_checks_if_unused_enabled_actions
    enum        = local.route53_health_checks_if_unused_enabled_actions_enum
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected unused Route53 health check ${param.title}."
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
            text     = "Skipped unused Route53 health check ${param.title}."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete_health_check" = {
          label        = "Delete Health Check"
          value        = "delete_health_check"
          style        = local.style_ok
          pipeline_ref = aws.pipeline.delete_route53_health_check
          pipeline_args = {
            region          = param.region
            conn            = param.conn
            health_check_id = param.id
          }
          success_msg = "Deleted unused Route53 health check ${param.title}."
          error_msg   = "Error deleting unused Route53 health check ${param.title}."
        }
      }
    }
  }
}