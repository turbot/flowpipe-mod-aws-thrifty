trigger "query" "detect_and_respond_to_s3_buckets_without_lifecycle_policy" {
  title       = "Detect and respond to S3 buckets without lifecycle policy"
  description = "Detects S3 buckets which do not have a lifecycle policy and responds with your chosen action."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = file("./s3/s3_buckets_without_lifecycle_policy.sql")

  capture "insert" {
    pipeline = pipeline.respond_to_s3_buckets_without_lifecycle_policy
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_s3_buckets_without_lifecycle_policy" {
  title         = "Detect and respond to S3 buckets without lifecycle policy"
  description   = "Detects S3 buckets which do not have a lifecycle policy and responds with your chosen action."
  tags          = merge(local.s3_common_tags, { class = "managed" })

  param "database" {
    type        = string
    description = local.DatabaseDescription
    default     = var.database
  }

  param "policy" {
    type        = string
    description = "Lifecycle policy to apply to the S3 bucket, if 'apply' is the chosen response."
    default     = var.s3_bucket_default_lifecycle_policy
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
    default     = var.s3_bucket_without_lifecycle_policy_default_response
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.s3_bucket_without_lifecycle_policy_responses
  }

  step "query" "detect" {
    database = param.database
    sql      = file("./s3/s3_buckets_without_lifecycle_policy.sql")
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_s3_buckets_without_lifecycle_policy
    args     = {
      items                    = step.query.detect.rows
      policy                   = param.policy
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
    }
  }
}

pipeline "respond_to_s3_buckets_without_lifecycle_policy" {
  title         = "Respond to S3 buckets without lifecycle policy"
  description   = "Responds to a collection of S3 buckets which do not have a lifecycle policy."
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
    default     = var.s3_bucket_default_lifecycle_policy
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
    default     = var.s3_bucket_without_lifecycle_policy_default_response
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.s3_bucket_without_lifecycle_policy_responses
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} S3 Buckets without a lifecycle policy."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.name => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_s3_bucket_without_lifecycle_policy
    args            = {
      title                    = each.value.title
      name                     = each.value.name
      region                   = each.value.region
      cred                     = each.value.cred
      policy                   = param.policy
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
    }
  }
}

pipeline "respond_to_s3_bucket_without_lifecycle_policy" {
  title         = "Respond to S3 bucket without lifecycle policy"
  description   = "Responds to an individual S3 bucket which does not have a lifecycle policy."
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
    default     = var.s3_bucket_default_lifecycle_policy
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
    default     = var.s3_bucket_without_lifecycle_policy_default_response
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.s3_bucket_without_lifecycle_policy_responses
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args     = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected S3 Bucket ${param.title} without a lifecycle policy."
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
      response_options = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.StyleInfo
          pipeline_ref  = local.approval_pipeline_skipped_action_notification
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