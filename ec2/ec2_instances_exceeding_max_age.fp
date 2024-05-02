locals {
  ec2_instances_exceeding_max_age_query = <<-EOQ
  select
    concat(instance_id, ' [', region, '/', account_id, ']') as title,
    instance_id,
    region,
    _ctx ->> 'connection_name' as cred
  from
    aws_ec2_instance
  where
    date_part('day', now()-launch_time) > ${var.ec2_instance_age_max_days}
    and instance_state in ('running', 'pending', 'rebooting')
  EOQ
}

trigger "query" "detect_and_respond_to_ec2_instances_exceeding_max_age" {
  title       = "Detect and respond to EC2 instances exceeding max age"
  description = "Detects EC2 instances exceeding max age and responds with your chosen action."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = local.ec2_instances_exceeding_max_age_query

  capture "insert" {
    pipeline = pipeline.respond_to_ec2_instances_exceeding_max_age
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_ec2_instances_exceeding_max_age" {
  title         = "Detect and respond to EC2 instances exceeding max age"
  description   = "Detects EC2 instances exceeding max age and responds with your chosen action."
  documentation = file("./ec2/ec2_instances_exceeding_max_age.md")
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
    default     = var.ec2_instance_age_max_days_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ec2_instance_age_max_days_responses
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ec2_instances_exceeding_max_age_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_ec2_instances_exceeding_max_age
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

pipeline "respond_to_ec2_instances_exceeding_max_age" {
  title         = "Respond to EC2 instances exceeding max age"
  description   = "Responds to a collection of EC2 instances exceeding max age."
  documentation = file("./ec2/ec2_instances_exceeding_max_age.md")
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
    default     = var.ec2_instance_age_max_days_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ec2_instance_age_max_days_responses
  }

  step "message" "notify_detection_count" {
    if       = var.notifier_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EC2 instances exceeding maximum age."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.instance_id => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_ec2_instance_exceeding_max_age
    args            = {
      title            = each.value.title
      instance_id      = each.value.instance_id
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

pipeline "respond_to_ec2_instance_exceeding_max_age" {
  title         = "Respond to EC2 instance exceeding max age"
  description   = "Responds to an EC2 instance exceeding max age."
  documentation = file("./ec2/ec2_instances_exceeding_max_age.md")
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
    default     = var.ec2_instance_age_max_days_default_response
  }

  param "responses" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ec2_instance_age_max_days_responses
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args     = {
      notifier         = param.notifier
      notifier_level   = param.notifier_level
      approvers        = param.approvers
      detect_msg       = "Detected EC2 Instance ${param.title} exceeding maximum age."
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
            text     = "Skipped EC2 Instance ${param.title} exceeding maximum age."
          }
          success_msg = ""
          error_msg   = ""
        },
        "stop" = {
          label  = "Stop"
          value  = "stop"
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
        "terminate" = {
          label  = "Terminate"
          value  = "terminate"
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