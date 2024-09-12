locals {
  route53_records_with_lower_ttl_query = <<-EOQ
  select
    concat(name, ' [', region, '/', account_id, ']') as title,
    name,
    region,
    zone_id,
    type,
    records,
    _ctx ->> 'connection_name' as cred
  from
    aws_route53_record
  where
    ttl :: int < 3600
  EOQ
}

trigger "query" "detect_and_correct_route53_records_with_lower_ttl" {
  title         = "Detect & correct Route53 records with lower TTL"
  description   = "Detects Route53 records with TTL lower than 3600 seconds and runs your chosen action."
  documentation = file("./pipelines/route53/docs/detect_and_correct_route53_records_with_lower_ttl_trigger.md")
  tags          = merge(local.route53_common_tags, { class = "higher" })

  enabled  = var.route53_records_with_lower_ttl_trigger_enabled
  schedule = var.route53_records_with_lower_ttl_trigger_schedule
  database = var.database
  sql      = local.route53_records_with_lower_ttl_query

  capture "insert" {
    pipeline = pipeline.correct_route53_records_with_lower_ttl
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_route53_records_with_lower_ttl" {
  title         = "Detect & correct Route53 records with lower TTL"
  description   = "Detects Route53 records with TTL lower than 3600 seconds and runs your chosen action."
  documentation = file("./pipelines/route53/docs/detect_and_correct_route53_records_with_lower_ttl.md")
  tags          = merge(local.route53_common_tags, { class = "higher", type = "recommended" })

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
    default     = var.route53_records_with_lower_ttl_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.route53_records_with_lower_ttl_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.route53_records_with_lower_ttl_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_route53_records_with_lower_ttl
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

pipeline "correct_route53_records_with_lower_ttl" {
  title         = "Correct Route53 records with lower TTL"
  description   = "Runs corrective action on a collection of Route53 records with TTL lower than 3600 seconds."
  documentation = file("./pipelines/route53/docs/correct_route53_records_with_lower_ttl.md")
  tags          = merge(local.route53_common_tags, { class = "higher" })

  param "items" {
    type = list(object({
      title   = string
      name    = string
      region  = string
      zone_id = string
      type    = string
      records = list(string)
      cred    = string
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
    default     = var.route53_records_with_lower_ttl_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.route53_records_with_lower_ttl_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} Route53 records with lower TTL."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.name => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_route53_record_with_lower_ttl
    args = {
      title              = each.value.title
      name               = each.value.name
      region             = each.value.region
      zone_id            = each.value.zone_id
      type               = each.value.type
      records            = each.value.records
      cred               = each.value.cred
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_one_route53_record_with_lower_ttl" {
  title         = "Correct one Route53 record with lower TTL"
  description   = "Runs corrective action on a Route53 record with TTL lower than 3600 seconds."
  documentation = file("./pipelines/route53/docs/correct_one_route53_record_with_lower_ttl.md")
  tags          = merge(local.route53_common_tags, { class = "higher" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "name" {
    type        = string
    description = "The name of the record."
  }

  param "zone_id" {
    type        = string
    description = "The ID of the hosted zone to contain this record."
  }

  param "type" {
    type        = string
    description = "The record type."
  }

  param "records" {
    type        = list(string)
    description = "The resource records."
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
    default     = var.route53_records_with_lower_ttl_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.route53_records_with_lower_ttl_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected Route53 record ${param.title} with lower TTL."
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
            text     = "Skipped Route53 record ${param.title}."
          }
          success_msg = ""
          error_msg   = ""
        },
        "update_ttl" = {
          label        = "Update TTL"
          value        = "update_ttl"
          style        = local.style_ok
          pipeline_ref = local.aws_pipeline_update_route53_record
          pipeline_args = {
            region         = param.region
            cred           = param.cred
            hosted_zone_id = param.zone_id
            record_name    = param.name
            record_type    = param.type
            record_ttl     = 3600
            record_values  = param.records
          }
          success_msg = "Updated Route53 record ${param.title} TTL to 3600."
          error_msg   = "Error updating Route53 record ${param.title} TTL to 3600"
        }
      }
    }
  }
}

variable "route53_records_with_lower_ttl_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/Route53"
  }
}

variable "route53_records_with_lower_ttl_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/Route53"
  }
}

variable "route53_records_with_lower_ttl_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  tags = {
    folder = "Advanced/Route53"
  }
}

variable "route53_records_with_lower_ttl_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "update_ttl"]
  tags = {
    folder = "Advanced/Route53"
  }
}