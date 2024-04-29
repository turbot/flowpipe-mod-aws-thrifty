locals {
  secretsmanager_secrets_unused_query = <<-EOQ
  select
    concat(name, ' [', region, '/', account_id, ']') as title,
    name,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_secretsmanager_secret
  where
    date_part('day', now()-last_accessed_date) > ${var.secretsmanager_secret_unused_days}::int
  EOQ
}

trigger "query" "detect_and_respond_to_secretsmanager_secrets_unused" {
  title       = "Detect and respond to SecretsManager secrets that are unused"
  description = "Detects SecretsManager secrets that are unused (not access in last n days) and responds with your chosen action."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = local.secretsmanager_secrets_unused_query

  capture "insert" {
    pipeline = pipeline.respond_to_secretsmanager_secrets_unused
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_secretsmanager_secrets_unused" {
  title         = "Detect and respond to SecretsManager secrets that are unused"
  description   = "Detects SecretsManager secrets that are unused (not access in last n days) and responds with your chosen action."
  documentation = file("./secretsmanager/secretsmanager_secret_unused.md")
  tags          = merge(local.secretsmanager_common_tags, { class = "unused" })

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

  param "notifier_level" {
    type        = string
    description = local.NotifierLevelDescription
    default     = var.notifier_level
  }

  param "approvers" {
    type        = list(string)
    description = local.ApproversDescription
    default     = var.approvers
  }

  param "default_response" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.secretsmanager_secret_unused_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.secretsmanager_secret_unused_responses
  }

  step "query" "detect" {
    database = param.database
    sql      = local.secretsmanager_secrets_unused_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_secretsmanager_secrets_unused
    args     = {
      items            = step.query.detect.rows
      notifier         = param.notifier
      notifier_level   = param.notifier_level
      approvers        = param.approvers
      default_response = param.default_response
      responses        = param.responses
    }
  }
}

pipeline "respond_to_secretsmanager_secrets_unused" {
  title         = "Respond to SecretsManager secrets that are unused"
  description   = "Responds to a collection of SecretsManager secrets that are unused (not access in last n days)."
  documentation = file("./secretsmanager/secretsmanager_secret_unused.md")
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
    description = local.NotifierDescription
    default     = var.notifier
  }

  param "notifier_level" {
    type        = string
    description = local.NotifierLevelDescription
    default     = var.notifier_level
  }

  param "approvers" {
    type        = list(string)
    description = local.ApproversDescription
    default     = var.approvers
  }

  param "default_response" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.secretsmanager_secret_unused_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.secretsmanager_secret_unused_responses
  }

  step "message" "notify_detection_count" {
    if       = var.notifier_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} SecretsManager secrets unused for ${var.secretsmanager_secret_unused_days} days."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.name => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_secretsmanager_secret_unused
    args            = {
      title            = each.value.title
      name             = each.value.name
      region           = each.value.region
      cred             = each.value.cred
      notifier         = param.notifier
      notifier_level   = param.notifier_level
      approvers        = param.approvers
      default_response = param.default_response
      responses        = param.responses
    }
  }
}

pipeline "respond_to_secretsmanager_secret_unused" {
  title         = "Respond to SecretsManager secret that are unused"
  description   = "Responds to a SecretsManager secret that are unused (not access in last n days)."
  documentation = file("./secretsmanager/secretsmanager_secret_unused.md")
  tags          = merge(local.secretsmanager_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "name" {
    type        = string
    description = "The friendly name of the SecretsManager secret."
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

  param "notifier_level" {
    type        = string
    description = local.NotifierLevelDescription
    default     = var.notifier_level
  }

  param "approvers" {
    type        = list(string)
    description = local.ApproversDescription
    default     = var.approvers
  }

  param "default_response" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.secretsmanager_secret_unused_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.secretsmanager_secret_unused_responses
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args     = {
      notifier         = param.notifier
      notifier_level   = param.notifier_level
      approvers        = param.approvers
      detect_msg       = "Detected SecretsManager secret ${param.title} unused for ${var.secretsmanager_secret_unused_days} days."
      default_response = param.default_response
      responses        = param.responses
      response_options = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.StyleInfo
          pipeline_ref  = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notifier_level == local.NotifierLevelVerbose
            text     = "Skipped SecretsManager secret ${param.title} unused for ${var.secretsmanager_secret_unused_days} days."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete" = {
          label  = "Delete"
          value  = "delete"
          style  = local.StyleAlert
          pipeline_ref  = pipeline.mock_aws_pipeline_delete_secretsmanager_secret // TODO: Replace with real pipeline when added to aws library mod.
          pipeline_args = {
            name   = param.name
            region = param.region
            cred   = param.cred
          }
          success_msg = "Deleted SecretsManager secret ${param.title}."
          error_msg   = "Error deleting SecretsManager secret ${param.title}."
        }
      }
    }
  }
}

// TODO: We can remove this mock pipeline once the real pipeline is added to the aws library mod.
pipeline "mock_aws_pipeline_delete_secretsmanager_secret" {
  param "name" {
    type = string
  }

  param "region" {
    type = string
  }

  param "cred" {
    type = string
  }

  output "result" {
    value = "Mocked: Delete SecretsManager secret [Name: ${param.name}, Region: ${param.region}, Cred: ${param.cred}]"
  }
}
