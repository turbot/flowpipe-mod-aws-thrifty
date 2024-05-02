locals {
  ec2_instances_older_generation_query = <<-EOQ
  select
    concat(instance_id, ' [', region, '/', account_id, ']') as title,
    instance_id,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_ec2_instance
  where
    instance_type like 't2.%' or instance_type like 'm3.%' or instance_type like 'm4.%'
  EOQ
}

trigger "query" "detect_and_respond_to_ec2_instances_older_generation" {
  title       = "Detect and respond to older generation EC2 instances"
  description = "Detects older generation EC2 instances and responds with your chosen action."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = local.ec2_instances_older_generation_query

  capture "insert" {
    pipeline = pipeline.respond_to_ec2_instances_older_generation
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_ec2_instances_older_generation" {
  title         = "Detect and respond to older generation EC2 instances"
  description   = "Detects older generation EC2 instances and responds with your chosen action."
  // tags          = merge(local.ec2_common_tags, {
  //   class = "unused" 
  // })

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
    default     = var.ec2_instance_older_generation_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ec2_instance_older_generation_enabled_response_options
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ec2_instances_older_generation_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_ec2_instances_older_generation
    args     = {
      items            = step.query.detect.rows
      notifier         = param.notifier
      notification_level   = param.notification_level
      approvers        = param.approvers
      default_response_option           = param. default_response_option
      enabled_response_options        = param. enabled_response_options
    }
  }
}

pipeline "respond_to_ec2_instances_older_generation" {
  title         = "Respond to older generation EC2 instances"
  description   = "Responds to a collection of older generation EC2 instances."
  // tags          = merge(local.ec2_common_tags, { 
  //   class = "deprecated" 
  // })

  param "items" {
    type = list(object({
      title       = string
      instance_id = string
      region      = string
      cred        = string
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
    default     = var.ec2_instance_older_generation_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ec2_instance_older_generation_enabled_response_options
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} older generation EC2 instances."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.instance_id => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_ec2_instance_older_generation
    args            = {
      title                      = each.value.title
      instance_id                = each.value.instance_id
      region                     = each.value.region
      cred                       = each.value.cred
      notifier                   = param.notifier
      notification_level         = param.notification_level
      approvers                  = param.approvers
      default_response_option    = param.default_response_option
      enabled_response_options   = param.enabled_response_options
    }
  }
}

pipeline "respond_to_ec2_instance_older_generation" {
  title         = "Respond to older generation EC2 instance"
  description   = "Responds to a older generation EC2 instance."
  // tags          = merge(local.ec2_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "instance_id" {
    type        = string
    description = "The ID of the EC2 instance."
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
    default     = var.ec2_instance_older_generation_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ec2_instance_older_generation_enabled_response_options
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args     = {
      notifier         = param.notifier
      notification_level   = param.notification_level
      approvers        = param.approvers
      detect_msg       = "Detected older generation EC2 Instance ${param.title}."
      default_response_option           = param. default_response_option
      enabled_response_options        = param. enabled_response_options
      response_options = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.StyleInfo
          pipeline_ref  = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped older generation EC2 Instance ${param.title}."
          }
          success_msg = "Skipped EC2 Instance ${param.title}."
          error_msg   = "Error skipping EC2 Instance ${param.title}."
        },
        "stop_instance" = {
          label  = "Stop Instance"
          value  = "stop_instance"
          style  = local.StyleAlert
          pipeline_ref  = local.aws_pipeline_stop_ec2_instances
          pipeline_args = {
            instance_ids = [param.instance_id]
            region       = param.region
            cred         = param.cred
          }
          success_msg = "Stopped EC2 Instance ${param.title}."
          error_msg   = "Error stopping EC2 Instance ${param.title}."
        }
        "terminate_instance" = {
          label  = "Terminate Instance"
          value  = "terminate_instance"
          style  = local.StyleAlert
          pipeline_ref  = local.aws_pipeline_terminate_ec2_instances
          pipeline_args = {
            instance_ids = [param.instance_id]
            region       = param.region
            cred         = param.cred
          }
          success_msg = "Deleted EC2 Instance ${param.title}."
          error_msg   = "Error deleting EC2 Instance ${param.title}."
        }
      }
    }
  }
}