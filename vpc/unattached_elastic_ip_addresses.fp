trigger "query" "unattached_elastic_ip_addresses" {
  title       = "Detect and respond to unattached elastic IP addresses(EIPs)"
  description = "Detects unattached elastic IP addresses and responds with your chosen action."
  //tags          = merge(local.vpc_common_tags, { class = "unused" })

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = file("./vpc/unattached_elastic_ip_addresses.sql")

  capture "insert" {
    pipeline = pipeline.respond_to_unattached_elastic_ip_addresses
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_unattached_elastic_ip_addresses" {
  title       = "Detect and respond to unattached elastic IP addresses(EIPs)"
  description = "Detects unattached elastic IP addresses and responds with your chosen action."
  // documentation = file("./vpc/unattached_elastic_ip_addresses.md")
  // tags          = merge(local.vpc_common_tags, { class = "unused" })

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
    default     = var.unattached_elastic_ip_addresses_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.unattached_elastic_ip_addresses_responses
  }

  step "query" "detect" {
    database = param.database
    sql      = file("./ebs/unattached_elastic_ip_addresses.sql")
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_unattached_elastic_ip_addresses
    args = {
      items            = step.query.detect.rows
      notifier         = param.notifier
      notifier_level   = param.notifier_level
      approvers        = param.approvers
      default_response = param.default_response
      responses        = param.responses
    }
  }
}

pipeline "respond_to_unattached_elastic_ip_addresses" {
  title       = "Respond to unattached elastic IP addresses"
  description = "Responds to a collection of elastic IP addresses which are unattached."
  // documentation = file("./vpc/unattached_elastic_ip_addresses.md")
  // tags          = merge(local.vpc_common_tags, { class = "unused" })

  param "items" {
    type = list(object({
      title         = string
      allocation_id = string
      region        = string
      cred          = string
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
    default     = var.unattached_elastic_ip_addresses_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.unattached_elastic_ip_addresses_responses
  }

  step "message" "notify_detection_count" {
    if       = var.notifier_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} elastic IP addresses unattached."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.allocation_id => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_unattached_elastic_ip_address
    args = {
      title            = each.value.title
      allocation_id    = each.value.allocation_id
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

pipeline "respond_to_unattached_elastic_ip_address" {
  title       = "Respond to elastic IP address unattached"
  description = "Responds to an elastic IP address unattached."
  // documentation = file("./vpc/unattached_elastic_ip_addresses.md")
  // tags          = merge(local.vpc_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "allocation_id" {
    type        = string
    description = "The ID representing the allocation of the address for use with EC2-VPC."
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
    default     = var.unattached_elastic_ip_addresses_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.unattached_elastic_ip_addresses_responses
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args = {
      notifier         = param.notifier
      notifier_level   = param.notifier_level
      approvers        = param.approvers
      detect_msg       = "Detected elastic IP address ${param.title} unattached."
      default_response = param.default_response
      responses        = param.responses
      response_options = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.StyleInfo
          pipeline_ref = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notifier_level == local.NotifierLevelVerbose
            text     = "Skipped elastic IP address ${param.title} unattached."
          }
          success_msg = ""
          error_msg   = ""
        },
        "release" = {
          label        = "Release"
          value        = "release"
          style        = local.StyleOk
          pipeline_ref = local.aws_pipeline_release_eip
          pipeline_args = {
            allocation_id = param.allocation_id
            region        = param.region
            cred          = param.cred
          }
          success_msg = "Released elastic IP address ${param.title}."
          error_msg   = "Error releasing elastic IP address ${param.title}."
        }
      }
    }
  }
}