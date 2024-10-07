locals {
  s3_buckets_without_lifecycle_policy_query = <<-EOQ
  select
    concat(name, ' [', account_id, ']') as title,
    name,
    region,
    sp_connection_name as conn
  from
    aws_s3_bucket
  where
    name = 'cody-test-actor-1'
    and lifecycle_rules is null;
  EOQ
}

variable "s3_buckets_without_lifecycle_policy_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/S3"
  }
}

variable "s3_buckets_without_lifecycle_policy_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/S3"
  }
}

variable "s3_buckets_without_lifecycle_policy_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  tags = {
    folder = "Advanced/S3"
  }
}

variable "s3_buckets_without_lifecycle_policy_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "apply_policy"]
  tags = {
    folder = "Advanced/S3"
  }
}

variable "s3_buckets_without_lifecycle_policy_default_policy" {
  type        = string
  description = "The default S3 bucket lifecycle policy to apply"
  default     = <<-EOF
{
  "Rules": [
    {
      "ID": "Transition to STANDARD_IA after 90 days",
      "Status": "Enabled",
      "Filter": {},
      "Transitions": [
        {
          "Days": 90,
          "StorageClass": "STANDARD_IA"
        }
      ]
    },
    {
      "ID": "Transition to GLACIER after 180 days",
      "Status": "Enabled",
      "Filter": {},
      "Transitions": [
        {
          "Days": 180,
          "StorageClass": "GLACIER"
        }
      ]
    },
    {
      "ID": "Transition to DEEP_ARCHIVE after 365 days",
      "Status": "Enabled",
      "Filter": {},
      "Transitions": [
        {
          "Days": 365,
          "StorageClass": "DEEP_ARCHIVE"
        }
      ]
    }
  ]
}
  EOF
}

trigger "query" "detect_and_correct_s3_buckets_without_lifecycle_policy" {
  title         = "Detect & correct S3 buckets without lifecycle policy"
  description   = "Detects S3 buckets which do not have a lifecycle policy and runs your chosen action."
  documentation = file("./pipelines/s3/docs/detect_and_correct_s3_buckets_without_lifecycle_policy_trigger.md")
  tags          = merge(local.s3_common_tags, { class = "managed" })

  enabled  = var.s3_buckets_without_lifecycle_policy_trigger_enabled
  schedule = var.s3_buckets_without_lifecycle_policy_trigger_schedule
  database = var.database
  sql      = local.s3_buckets_without_lifecycle_policy_query

  capture "insert" {
    pipeline = pipeline.correct_s3_buckets_without_lifecycle_policy
    args = {
      items = self.inserted_rows
    }
  }

  capture "update" {
    pipeline = pipeline.correct_s3_buckets_without_lifecycle_policy
    args = {
      items = self.updated_rows
    }
  }
}

pipeline "detect_and_correct_s3_buckets_without_lifecycle_policy" {
  title         = "Detect & correct S3 buckets without lifecycle policy"
  description   = "Detects S3 buckets which do not have a lifecycle policy and runs your chosen action."
  documentation = file("./pipelines/s3/docs/detect_and_correct_s3_buckets_without_lifecycle_policy.md")
  tags          = merge(local.s3_common_tags, { class = "managed", type = "recommended" })

  param "database" {
    type        = connection.steampipe
    description = local.description_database
    default     = var.database
  }

  param "policy" {
    type        = string
    description = "Lifecycle policy to apply to the S3 bucket, if 'apply' is the chosen response."
    default     = var.s3_buckets_without_lifecycle_policy_default_policy
  }

  /*
  param "notifier" {
    type        = notifier
    description = local.description_notifier
    #default     = notifier.default
    default     = var.notifier
  }
  */

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = [notifier.default]
    #default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.s3_buckets_without_lifecycle_policy_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.s3_buckets_without_lifecycle_policy_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.s3_buckets_without_lifecycle_policy_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_s3_buckets_without_lifecycle_policy
    args = {
      items              = step.query.detect.rows
      policy             = param.policy
      #notifier           = param.notifier
      notifier           = notifier.default
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_s3_buckets_without_lifecycle_policy" {
  title         = "Correct S3 buckets without lifecycle policy"
  description   = "Runs corrective action on a collection of S3 buckets which do not have a lifecycle policy."
  documentation = file("./pipelines/s3/docs/correct_s3_buckets_without_lifecycle_policy.md")
  tags          = merge(local.s3_common_tags, { class = "managed", type = "internal" })

  param "items" {
    type = list(object({
      title  = string
      name   = string
      region = string
      conn   = string
    }))
  }

  param "policy" {
    type        = string
    description = "Lifecycle policy to apply to the S3 bucket, if 'apply' is the chosen response."
    default     = var.s3_buckets_without_lifecycle_policy_default_policy
  }

  /*
  param "notifier" {
    type        = notifier
    description = local.description_notifier
    #default     = notifier.default
    default     = var.notifier
  }
  */

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = [notifier.default]
    #default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.s3_buckets_without_lifecycle_policy_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.s3_buckets_without_lifecycle_policy_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_info
    #notifier = notifier[param.notifier]
    notifier = notifier.default
    text     = "Detected ${length(param.items)} S3 Buckets without a lifecycle policy."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.name => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_s3_bucket_without_lifecycle_policy
    args = {
      title              = each.value.title
      name               = each.value.name
      region             = each.value.region
      conn               = each.value.conn
      policy             = param.policy
      #notifier           = param.notifier
      notifier           = notifier.default
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_one_s3_bucket_without_lifecycle_policy" {
  title         = "Correct one S3 bucket without lifecycle policy"
  description   = "Runs corrective action on an individual S3 bucket which does not have a lifecycle policy."
  documentation = file("./pipelines/s3/docs/correct_one_s3_bucket_without_lifecycle_policy.md")
  tags          = merge(local.s3_common_tags, { class = "managed", type = "internal" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "name" {
    type        = string
    description = "Name of the S3 Bucket."
  }

  param "region" {
    type        = string
    description = local.description_region
  }

  param "conn" {
    type        = connection.aws
    description = local.description_connection
  }

  param "policy" {
    type        = string
    description = "Lifecycle policy to apply to the S3 Bucket."
    default     = var.s3_buckets_without_lifecycle_policy_default_policy
  }

  /*
  param "notifier" {
    type        = notifier
    description = local.description_notifier
    #default     = notifier.default
    default     = var.notifier
  }
  */

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = [notifier.default]
    #default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.s3_buckets_without_lifecycle_policy_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.s3_buckets_without_lifecycle_policy_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = notifier.default
      #notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected S3 Bucket ${param.title} without a lifecycle policy."
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
      actions = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.style_info
          pipeline_ref = local.pipeline_optional_message
          pipeline_args = {
            notifier = notifier.default
            #notifier = param.notifier
            send     = param.notification_level == local.level_verbose
            text     = "Skipped S3 Bucket ${param.title} without a lifecycle policy."
          }
          success_msg = ""
          error_msg   = ""
        }
        "apply_policy" = {
          label        = "Apply Policy"
          value        = "apply_policy"
          style        = local.style_ok
          pipeline_ref = aws.pipeline.put_s3_bucket_lifecycle_policy
          pipeline_args = {
            bucket_name = param.name
            region      = param.region
            conn        = param.conn
            policy      = param.policy
          }
          success_msg = "Applied lifecycle policy to S3 Bucket ${param.title}."
          error_msg   = "Error applying lifecycle policy to S3 Bucket ${param.title}."
        }
      }
    }
  }
}
