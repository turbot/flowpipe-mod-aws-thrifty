locals {
  secretsmanager_secrets_if_unused_query = <<-EOQ
  select
    concat(name, ' [', region, '/', account_id, ']') as title,
    name,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_secretsmanager_secret
  where
    date_part('day', now()-last_accessed_date) > ${var.secretsmanager_secrets_if_unused_days}::int
  EOQ
}

trigger "query" "detect_and_correct_secretsmanager_secrets_if_unused" {
  title       = "Detect & correct SecretsManager secrets if unused"
  description = "Detects SecretsManager secrets that are unused (not accessed in last n days) and runs your chosen action."
  documentation = file("./pipelines/secretsmanager/docs/detect_and_correct_secretsmanager_secrets_if_unused_trigger.md")
  tags          = merge(local.secretsmanager_common_tags, { class = "unused" })

  enabled  = var.secretsmanager_secrets_if_unused_trigger_enabled
  schedule = var.secretsmanager_secrets_if_unused_trigger_schedule
  database = var.database
  sql      = local.secretsmanager_secrets_if_unused_query

  capture "insert" {
    pipeline = pipeline.correct_secretsmanager_secrets_if_unused
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_secretsmanager_secrets_if_unused" {
  title         = "Detect & correct SecretsManager secrets if unused"
  description   = "Detects SecretsManager secrets that are unused (not accessed in last n days) and runs your chosen action."
  documentation = file("./pipelines/secretsmanager/docs/detect_and_correct_secretsmanager_secrets_if_unused.md")
  tags          = merge(local.secretsmanager_common_tags, { class = "unused", type = "featured" })

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
    default     = var.secretsmanager_secrets_if_unused_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.secretsmanager_secrets_if_unused_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.secretsmanager_secrets_if_unused_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_secretsmanager_secrets_if_unused
    args     = {
      items              = step.query.detect.rows
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_secretsmanager_secrets_if_unused" {
  title         = "Correct SecretsManager secrets if unused"
  description   = "Runs corrective action on a collection of SecretsManager secrets that are unused (not access in last n days)."
  documentation = file("./pipelines/secretsmanager/docs/correct_secretsmanager_secrets_if_unused.md")
  tags          = merge(local.secretsmanager_common_tags, { class = "unused" })

  param "items" {
    type = list(object({
      title  = string
      name   = string
      region = string
      cred   = string
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
    default     = var.secretsmanager_secrets_if_unused_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.secretsmanager_secrets_if_unused_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} SecretsManager secrets unused for ${var.secretsmanager_secrets_if_unused_days} days."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.name => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_secretsmanager_secret_if_unused
    args            = {
      title              = each.value.title
      name               = each.value.name
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

pipeline "correct_one_secretsmanager_secret_if_unused" {
  title         = "Correct one SecretsManager secret if unused"
  description   = "Runs corrective action on a SecretsManager secret that are unused (not access in last n days)."
  documentation = file("./pipelines/secretsmanager/docs/correct_one_secretsmanager_secret_if_unused.md")
  tags          = merge(local.secretsmanager_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "name" {
    type        = string
    description = "The friendly name of the SecretsManager secret."
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
    default     = var.secretsmanager_secrets_if_unused_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.secretsmanager_secrets_if_unused_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args     = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected SecretsManager secret ${param.title} unused for ${var.secretsmanager_secrets_if_unused_days} days."
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
      actions = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.style_info
          pipeline_ref = local.pipeline_optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.level_verbose
            text     = "Skipped SecretsManager secret ${param.title} unused for ${var.secretsmanager_secrets_if_unused_days} days."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete_secret" = {
          label        = "Delete Secret"
          value        = "delete_secret"
          style        = local.style_alert
          pipeline_ref = local.aws_pipeline_delete_secretsmanager_secret
          pipeline_args = {
            name      = param.name
            region    = param.region
            cred      = param.cred
            secret_id = param.name
          }
          success_msg = "Deleted SecretsManager secret ${param.title}."
          error_msg   = "Error deleting SecretsManager secret ${param.title}."
        }
      }
    }
  }
}

variable "secretsmanager_secrets_if_unused_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
}

variable "secretsmanager_secrets_if_unused_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
}

variable "secretsmanager_secrets_if_unused_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
}

variable "secretsmanager_secrets_if_unused_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_secret"]
}

variable "secretsmanager_secrets_if_unused_days" {
  type        = number
  description = "The default number of days secrets manager secrets to be considered in-use."
  default     = 90
}