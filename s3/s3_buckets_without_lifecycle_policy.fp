locals {
  s3_buckets_without_lifecycle_policy_query = <<-EOQ
  select
    concat(name, ' [', account_id, ']') as title,
    name,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_s3_bucket
  where
    lifecycle_rules is null;
  EOQ
}

trigger "query" "detect_and_correct_s3_buckets_without_lifecycle_policy" {
  title       = "Detect & correct S3 buckets without lifecycle policy"
  description = "Detects S3 buckets which do not have a lifecycle policy and runs your chosen action."

  enabled  = var.s3_buckets_without_lifecycle_policy_trigger_enabled
  schedule = var.s3_buckets_without_lifecycle_policy_trigger_schedule
  database = var.database
  sql      = local.s3_buckets_without_lifecycle_policy_query

  capture "insert" {
    pipeline = pipeline.correct_s3_buckets_without_lifecycle_policy
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_s3_buckets_without_lifecycle_policy" {
  title         = "Detect & correct S3 buckets without lifecycle policy"
  description   = "Detects S3 buckets which do not have a lifecycle policy and runs your chosen action."
  tags          = merge(local.s3_common_tags, { class = "managed" })

  param "database" {
    type        = string
    description = local.DatabaseDescription
    default     = var.database
  }

  param "policy" {
    type        = string
    description = "Lifecycle policy to apply to the S3 bucket, if 'apply' is the chosen response."
    default     = var.s3_buckets_without_lifecycle_policy_default_policy
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
    default     = var.s3_buckets_without_lifecycle_policy_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.s3_buckets_without_lifecycle_policy_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.s3_buckets_without_lifecycle_policy_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_s3_buckets_without_lifecycle_policy
    args     = {
      items                    = step.query.detect.rows
      policy                   = param.policy
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
    }
  }
}

pipeline "correct_s3_buckets_without_lifecycle_policy" {
  title         = "Corrects S3 buckets without lifecycle policy"
  description   = "Runs corrective action on a collection of S3 buckets which do not have a lifecycle policy."
  tags          = merge(local.s3_common_tags, { class = "managed" })

  param "items" {
    type = list(object({
      title  = string
      name   = string
      region = string
      cred   = string
    }))
  }

  param "policy" {
    type        = string
    description = "Lifecycle policy to apply to the S3 bucket, if 'apply' is the chosen response."
    default     = var.s3_buckets_without_lifecycle_policy_default_policy
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
    default     = var.s3_buckets_without_lifecycle_policy_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.s3_buckets_without_lifecycle_policy_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} S3 Buckets without a lifecycle policy."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.name => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_s3_bucket_without_lifecycle_policy
    args            = {
      title                    = each.value.title
      name                     = each.value.name
      region                   = each.value.region
      cred                     = each.value.cred
      policy                   = param.policy
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
    }
  }
}

pipeline "correct_one_s3_bucket_without_lifecycle_policy" {
  title         = "Correct one S3 bucket without lifecycle policy"
  description   = "Runs corrective action on an individual S3 bucket which does not have a lifecycle policy."
  tags          = merge(local.s3_common_tags, { class = "managed" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "name" {
    type        = string
    description = "Name of the S3 Bucket."
  }

  param "region" {
    type        = string
    description = local.RegionDescription
  }

  param "cred" {
    type        = string
    description = local.CredentialDescription
  }

  param "policy" {
    type        = string
    description = "Lifecycle policy to apply to the S3 Bucket."
    default     = var.s3_buckets_without_lifecycle_policy_default_policy
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
    default     = var.s3_buckets_without_lifecycle_policy_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.s3_buckets_without_lifecycle_policy_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args     = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected S3 Bucket ${param.title} without a lifecycle policy."
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
      actions = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.StyleInfo
          pipeline_ref  = local.pipeline_optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped S3 Bucket ${param.title} without a lifecycle policy."
          }
          success_msg = ""
          error_msg   = ""
        }
        "apply_policy" = {
          label  = "Apply Policy"
          value  = "apply_policy"
          style  = local.StyleOk
          pipeline_ref  = pipeline.mock_aws_pipeline_put_s3_lifecycle_policy // TODO: Replace with real pipeline when added to aws library mod.
          pipeline_args = {
            bucket_name = param.name
            region      = param.region
            cred        = param.cred
            policy      = param.policy
          }
          success_msg = "Applied lifecycle policy to S3 Bucket ${param.title}."
          error_msg   = "Error applying lifecycle policy to S3 Bucket ${param.title}."
        }
      }
    }
  }
}

// TODO: We can remove this mock pipeline once the real pipeline is added to the aws library mod.
pipeline "mock_aws_pipeline_put_s3_lifecycle_policy" {
  param "bucket_name" {
    type = string
  }

  param "region" {
    type = string
  }

  param "cred" {
    type = string
  }

  param "policy" {
    type = string
  }

  output "result" {
    value = "Mocked: Put S3 Lifecycle Policy [Name: ${param.bucket_name}, Region: ${param.region}, Cred: ${param.cred}]\n${param.policy}"
  }
}

variable "s3_buckets_without_lifecycle_policy_trigger_enabled" {
  type    = bool
  default = false
}

variable "s3_buckets_without_lifecycle_policy_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "s3_buckets_without_lifecycle_policy_default_action" {
  type        = string
  description = "The default response to use for S3 buckets without lifecycle policy."
  default     = "notify"
}

variable "s3_buckets_without_lifecycle_policy_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "apply_policy"]
}

// TODO: Change to an array of objects (contents of 'Rules') - let lib mod wrap it; no JSONified strings!
// TODO: Safer default (no deletion) - check other variables!
variable "s3_buckets_without_lifecycle_policy_default_policy" {
  type        = string
  description = "The default S3 bucket lifecycle policy to apply"
  default     = <<-EOF
{
  "Rules": [
    {
      "ID": "Expire all objects after one year",
      "Status": "Enabled",
      "Expiration": {
        "Days": 365
      }
    }
  ]
}
  EOF
}