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

trigger "query" "detect_and_correct_ec2_instances_exceeding_max_age" {
  title       = "Detect & correct EC2 instances exceeding max age"
  description = "Detects EC2 instances exceeding max age and runs your chosen action."

  enabled  = var.ec2_instances_exceeding_max_age_trigger_enabled
  schedule = var.ec2_instances_exceeding_max_age_trigger_schedule
  database = var.database
  sql      = local.ec2_instances_exceeding_max_age_query

  capture "insert" {
    pipeline = pipeline.correct_ec2_instances_exceeding_max_age
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ec2_instances_exceeding_max_age" {
  title         = "Detect & correct EC2 instances exceeding max age"
  description   = "Detects EC2 instances exceeding max age and runs your chosen action."
  // tags          = merge(local.ec2_common_tags, {
  //   class = "unused" 
  // })

  param "database" {
    type        = string
    description = local.description_database
    default     = var.database
  }

  param "notifier" {
    type        = string
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(string)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ec2_instance_age_max_days_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_instance_age_max_days_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ec2_instances_exceeding_max_age_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ec2_instances_exceeding_max_age
    args     = {
      items                    = step.query.detect.rows
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
    }
  }
}

pipeline "correct_ec2_instances_exceeding_max_age" {
  title         = "Corrects EC2 instances exceeding max age"
  description   = "Runs corrective action on a collection of EC2 instances exceeding max age."
  // tags          = merge(local.ec2_common_tags, { 
  //   class = "unused" 
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
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(string)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ec2_instance_age_max_days_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_instance_age_max_days_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EC2 instances exceeding maximum age."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.instance_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ec2_instance_exceeding_max_age
    args            = {
      title            = each.value.title
      instance_id      = each.value.instance_id
      region           = each.value.region
      cred             = each.value.cred
      notifier         = param.notifier
      notification_level   = param.notification_level
      approvers        = param.approvers
      default_action           = param.default_action
      enabled_actions        = param.enabled_actions
    }
  }
}

pipeline "correct_one_ec2_instance_exceeding_max_age" {
  title         = "Correct one EC2 instance exceeding max age"
  description   = "Runs corrective action on an EC2 instance exceeding max age."
  // tags          = merge(local.ec2_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "instance_id" {
    type        = string
    description = "The ID of the EC2 instance."
  }

  param "region" {
    type        = string
    description = local.description_region
  }

  param "cred" {
    type        = string
    description = local.description_credential
  }

  param "notifier" {
    type        = string
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(string)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ec2_instance_age_max_days_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_instance_age_max_days_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args     = {
      notifier         = param.notifier
      notification_level   = param.notification_level
      approvers        = param.approvers
      detect_msg       = "Detected EC2 Instance ${param.title} exceeding maximum age."
      default_action           = param.default_action
      enabled_actions        = param.enabled_actions
      actions = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.StyleInfo
          pipeline_ref  = local.pipeline_optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped EC2 Instance ${param.title} exceeding maximum age."
          }
          success_msg = "Skipping EC2 Instance ${param.title}."
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