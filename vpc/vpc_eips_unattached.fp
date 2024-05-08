locals {
  vpc_eips_unattached_query = <<-EOQ
select
  concat(allocation_id, ' [', region, '/', account_id, ']') as title,
  allocation_id,
  region,
  _ctx ->> 'connection_name' as cred
from
  aws_vpc_eip
where
  association_id is null;
  EOQ
}

trigger "query" "detect_and_correct_vpc_eips_unattached" {
  title       = "Detect & correct unattached EIPs"
  description = "Detects unattached EIPs (Elastic IP addresses) and runs your chosen action."
  //tags          = merge(local.vpc_common_tags, { class = "unused" })

  enabled  = var.vpc_unattached_eips_trigger_enabled
  schedule = var.vpc_unattached_eips_trigger_scheduled
  database = var.database
  sql      = local.vpc_eips_unattached_query

  capture "insert" {
    pipeline = pipeline.correct_vpc_eips_unattached
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_vpc_eips_unattached" {
  title       = "Detect & correct unattached EIPs"
  description = "Detects unattached EIPs (Elastic IP addresses) and runs your chosen action."
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
    default     = var.vpc_eips_unattached_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.vpc_eips_unattached_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.vpc_eips_unattached_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_vpc_eips_unattached
    args = {
      items                    = step.query.detect.rows
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
    }
  }
}

pipeline "correct_vpc_eips_unattached" {
  title       = "Corrects unattached EIPs"
  description = "Runs corrective action on a collection of EIPs (Elastic IP addresses) which are unattached."
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
    default     = var.vpc_eips_unattached_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.vpc_eips_unattached_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} elastic IP addresses unattached."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.allocation_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_vpc_eip_unattached
    args = {
      title                    = each.value.title
      allocation_id            = each.value.allocation_id
      region                   = each.value.region
      cred                     = each.value.cred
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
    }
  }
}

pipeline "correct_one_vpc_eip_unattached" {
  title       = "Correct one EIPs unattached"
  description = "Runs corrective action on an EIPs (Elastic IP addresses) unattached."
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
    default     = var.vpc_eips_unattached_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.vpc_eips_unattached_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected elastic IP address ${param.title} unattached."
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
      actions = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.StyleInfo
          pipeline_ref = local.pipeline_optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
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

pipeline "mock_aws_pipeline_release_eip" {
  param "allocation_id" {
    type        = string
  }

  param "region" {
    type        = string
  }

  param "cred" {
    type        = string
  }

  output "result" {
    value = "Mocked: Release EIP [Allocation ID: ${param.allocation_id}, Region: ${param.region}, Cred: ${param.cred}]"
  }
}