trigger "query" "detect_and_respond_to_ebs_volumes_without_attachments" {
  title         = "Detect and respond to EBS volumes without attachments"
  description   = "Detects EBS volumes without attachments and responds with your chosen action."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = file("./ebs/ebs_volumes_without_attachments.sql")

  capture "insert" {
    pipeline = pipeline.respond_to_ebs_volumes_without_attachments
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_ebs_volumes_without_attachments" {
  title         = "Detect and respond to EBS volumes without attachments"
  description   = "Detects EBS volumes without attachments and responds with your chosen action."
  // tags          = merge(local.ebs_common_tags, { class = "unused" })

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
    default     = var.ebs_volume_without_attachments_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_without_attachments_enabled_response_options
  }

  step "query" "detect" {
    database = var.database
    sql      = file("./ebs/ebs_volumes_without_attachments.sql")
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_ebs_volumes_without_attachments
    args     = {
      items                    = step.query.detect.rows
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
    }
  }
}

pipeline "respond_to_ebs_volumes_without_attachments" {
  title         = "Respond to EBS volumes without attachments"
  description   = "Responds to a collection of EBS volumes without attachments."
  // tags          = merge(local.ebs_common_tags, { class = "unused" })

  param "items" {
    type = list(object({
      title     = string
      volume_id = string
      region    = string
      cred      = string
    }))
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
    default     = var.ebs_volume_without_attachments_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_without_attachments_enabled_response_options
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EBS volumes without attachments."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.volume_id => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_ebs_volume_without_attachments
    args            = {
      title                    = each.value.title
      volume_id                = each.value.volume_id
      region                   = each.value.region
      cred                     = each.value.cred
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
    }
  }
}

pipeline "respond_to_ebs_volume_without_attachments" {
  title         = "Respond to EBS volume without attachments"
  description   = "Responds to an EBS volume without attachments."
  // tags          = merge(local.ebs_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "volume_id" {
    type        = string
    description = "EBS volume ID."
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
    default     = var.ebs_volume_without_attachments_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_without_attachments_enabled_response_options
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args     = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected EBS volume ${param.title} using gp2."
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
            text     = "Skipped EBS volume ${param.title} using gp2."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete_volume" = {
          label  = "Delete Volume"
          value  = "delete_volume"
          style  = local.StyleAlert
          pipeline_ref  = pipeline.mock_aws_pipeline_delete_ebs_volume // TODO: Replace with real pipeline when added to aws library mod.
          pipeline_args = {
            volume_id   = param.volume_id
            region      = param.region
            cred        = param.cred
          }
          success_msg = "Deleted EBS volume ${param.title}."
          error_msg   = "Error deleting EBS volume ${param.title}"
        }
      }
    }
  }
}

// TODO: We can remove this mock pipeline once the real pipeline is added to the aws library mod.
pipeline "mock_aws_pipeline_delete_ebs_volume" {
  param "volume_id" {
    type = string
  }

  param "region" {
    type = string
  }

  param "cred" {
    type = string
  }

  output "result" {
    value = "Mocked: Delete EBS Volume [Volume_ID: ${param.volume_id}, Region: ${param.region}, Cred: ${param.cred}]"
  }
}