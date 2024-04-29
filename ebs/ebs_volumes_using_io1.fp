trigger "query" "detect_and_respond_to_ebs_volumes_using_io1" {
  title         = "Detect and respond to EBS volumes using io1"
  description   = "Detects EBS volumes using io1 and responds with your chosen action."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = file("./ebs/ebs_volumes_using_io1.sql")

  capture "insert" {
    pipeline = pipeline.respond_to_ebs_volumes_using_io1
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_ebs_volumes_using_io1" {
  title         = "Detect and respond to EBS volumes using io1"
  description   = "Detects EBS volumes using io1 and responds with your chosen action."
  // documentation = file("./ebs/ebs_volumes_using_io1.md")
  // tags          = merge(local.ebs_common_tags, { class = "deprecated" })

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
    default     = var.ebs_volume_using_io1_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_using_io1_responses
  }

  step "query" "detect" {
    database = param.database
    sql      = file("./ebs/ebs_volumes_using_io1.sql")
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_ebs_volumes_using_io1
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

pipeline "respond_to_ebs_volumes_using_io1" {
  title         = "Respond to EBS volumes using io1"
  description   = "Responds to a collection of EBS volumes using io1."
  // documentation = file("./ebs/ebs_volumes_using_io1.md")
  // tags          = merge(local.ebs_common_tags, { class = "deprecated" })

  param "items" {
    type = list(object({
      title      = string
      volume_id  = string
      region     = string
      cred       = string
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
    default     = var.ebs_volume_using_io1_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_using_io1_responses
  }

  step "message" "notify_detection_count" {
    if       = var.notifier_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EBS volumes using io1."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.volume_id => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_ebs_volume_using_io1
    args            = {
      title            = each.value.title
      volume_id        = each.value.volume_id
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

pipeline "respond_to_ebs_volume_using_io1" {
  title         = "Respond to EBS volume using io1"
  description   = "Responds to an EBS volume using io1."
  // documentation = file("./ebs/ebs_volumes_using_io1.md")
  // tags          = merge(local.ebs_common_tags, { class = "deprecated" })

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
    default     = var.ebs_volume_using_io1_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volume_using_io1_responses
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args     = {
      notifier         = param.notifier
      notifier_level   = param.notifier_level
      approvers        = param.approvers
      detect_msg       = "Detected EBS volume ${param.title} using io1."
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
            text     = "Skipped EBS volume ${param.title} using io1."
          }
          success_msg = ""
          error_msg   = ""
        },
        "update" = {
          label  = "Update to io2"
          value  = "update"
          style  = local.StyleOk
          pipeline_ref  = local.aws_pipeline_modify_ebs_volume
          pipeline_args = {
            volume_id   = param.volume_id
            volume_type = "io2"
            region      = param.region
            cred        = param.cred
          }
          success_msg = "Updated EBS volume ${param.title} to io2."
          error_msg   = "Error updating EBS volume ${param.title} to io2"
        }
      }
    }
  }
}