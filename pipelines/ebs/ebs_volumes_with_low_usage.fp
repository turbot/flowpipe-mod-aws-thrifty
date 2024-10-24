locals {
  ebs_volumes_with_low_usage_query = <<-EOQ
  with ebs_usage as (
  select
    account_id,
    sp_connection_name,
    region,
    volume_id,
    round(avg(max)) as avg_max
  from
    (
      (
        select
          partition,
          account_id,
          sp_connection_name,
          region,
          volume_id,
          cast(maximum as numeric) as max
        from
          aws_ebs_volume_metric_read_ops_daily
        where
          date_part('day', now() - timestamp) <= 30
      )
      union
      (
        select
          partition,
          account_id,
          sp_connection_name,
          region,
          volume_id,
          cast(maximum as numeric) as max
        from
          aws_ebs_volume_metric_write_ops_daily
        where
          date_part('day', now() - timestamp) <= 30
      )
    ) as read_and_write_ops
  group by
    1,
    2,
    3,
    4,
    5
  )
  select
    concat(volume_id, ' [', region, '/', account_id, ']') as title,
    volume_id,
    region,
    sp_connection_name as conn
  from
    ebs_usage
  where
    avg_max <= ${var.ebs_volumes_with_low_usage_min}::int
  EOQ

  ebs_volumes_with_low_usage_default_action_enum  = ["notify", "skip", "delete_volume"]
  ebs_volumes_with_low_usage_enabled_actions_enum = ["skip", "delete_volume"]
}

variable "ebs_volumes_with_low_usage_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_with_low_usage_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_with_low_usage_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "delete_volume"]
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_with_low_usage_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_volume"]
  enum        = ["skip", "delete_volume"]
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_with_low_usage_min" {
  type        = number
  description = "The number of average read/write ops required for volumes to be considered infrequently used."
  default     = 100
  tags = {
    folder = "Advanced/EBS"
  }
}

trigger "query" "detect_and_correct_ebs_volumes_with_low_usage" {
  title         = "Detect & correct EBS volumes with low usage"
  description   = "Detects EBS volumes with low usage and runs your chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_volumes_with_low_usage_trigger.md")
  tags          = merge(local.ebs_common_tags, { class = "unused" })

  enabled  = var.ebs_volumes_with_low_usage_trigger_enabled
  schedule = var.ebs_volumes_with_low_usage_trigger_schedule
  database = var.database
  sql      = local.ebs_volumes_with_low_usage_query

  capture "insert" {
    pipeline = pipeline.correct_ebs_volumes_with_low_usage
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ebs_volumes_with_low_usage" {
  title         = "Detect & correct EBS volumes with low usage"
  description   = "Detects EBS volumes with low usage and runs your chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_volumes_with_low_usage.md")
  tags          = merge(local.ebs_common_tags, { class = "unused", recommended = "true" })

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
    default     = var.ebs_volumes_with_low_usage_default_action
    enum        = local.ebs_volumes_with_low_usage_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_with_low_usage_enabled_actions
    enum        = local.ebs_volumes_with_low_usage_enabled_actions_enum
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_volumes_with_low_usage_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ebs_volumes_with_low_usage
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

pipeline "correct_ebs_volumes_with_low_usage" {
  title         = "Correct EBS volumes with low usage"
  description   = "Runs corrective action on a collection of EBS volumes with low usage."
  documentation = file("./pipelines/ebs/docs/correct_ebs_volumes_with_low_usage.md")
  tags          = merge(local.ebs_common_tags, { class = "unused", folder = "Internal" })

  param "items" {
    type = list(object({
      title     = string
      volume_id = string
      region    = string
      conn      = string
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
    default     = var.ebs_volumes_with_low_usage_default_action
    enum        = local.ebs_volumes_with_low_usage_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_with_low_usage_enabled_actions
    enum        = local.ebs_volumes_with_low_usage_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected ${length(param.items)} EBS volumes with low usage."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.volume_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ebs_volume_with_low_usage
    args = {
      title              = each.value.title
      volume_id          = each.value.volume_id
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

pipeline "correct_one_ebs_volume_with_low_usage" {
  title         = "Correct one EBS volume with low usage"
  description   = "Runs corrective action on an EBS volume with low usage."
  documentation = file("./pipelines/ebs/docs/correct_one_ebs_volume_with_low_usage.md")
  tags          = merge(local.ebs_common_tags, { class = "unused", folder = "Internal" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "volume_id" {
    type        = string
    description = "The ID of the EBS volume."
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
    default     = var.ebs_volumes_with_low_usage_default_action
    enum        = local.ebs_volumes_with_low_usage_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_with_low_usage_enabled_actions
    enum        = local.ebs_volumes_with_low_usage_enabled_actions_enum
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected EBS Volume ${param.title} with low usage."
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
            text     = "Skipped EBS Volume ${param.title} with low usage."
          }
          success_msg = "Skipped EBS Volume ${param.title}."
          error_msg   = "Error skipping EBS Volume ${param.title}."
        },
        "delete_volume" = {
          label        = "Delete_volume"
          value        = "delete_volume"
          style        = local.style_alert
          pipeline_ref = aws.pipeline.delete_ebs_volume
          pipeline_args = {
            volume_id = param.volume_id
            region    = param.region
            conn      = param.conn
          }
          success_msg = "Deleted EBS Volume ${param.title}."
          error_msg   = "Error deleting EBS Volume ${param.title}."
        }
      }
    }
  }
}
