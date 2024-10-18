locals {
  ec2_instances_without_graviton_query = <<-EOQ
  select
    concat(instance_id, ' [', region, '/', account_id, ']') as title,
    instance_id,
    region,
    sp_connection_name as conn
  from
    aws_ec2_instance
  where
    platform != 'windows'
    and architecture != 'arm64';
  EOQ

  ec2_instances_without_graviton_default_action_enum  = ["notify", "skip", "stop_instance", "terminate_instance"]
  ec2_instances_without_graviton_enabled_actions_enum = ["skip", "stop_instance", "terminate_instance"]
}

variable "ec2_instances_without_graviton_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/EC2"
  }
}

variable "ec2_instances_without_graviton_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/EC2"
  }
}

variable "ec2_instances_without_graviton_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "stop_instance", "terminate_instance"]
  tags = {
    folder = "Advanced/EC2"
  }
}

variable "ec2_instances_without_graviton_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "stop_instance", "terminate_instance"]
  enum        = ["skip", "stop_instance", "terminate_instance"]
  tags = {
    folder = "Advanced/EC2"
  }
}

trigger "query" "detect_and_correct_ec2_instances_without_graviton" {
  title         = "Detect & correct EC2 instances without graviton"
  description   = "Detects EC2 instances without graviton processor and runs your chosen action."
  documentation = file("./pipelines/ec2/docs/detect_and_correct_ec2_instances_without_graviton_trigger.md")
  tags          = merge(local.ec2_common_tags, { class = "deprecated" })

  enabled  = var.ec2_instances_without_graviton_trigger_enabled
  schedule = var.ec2_instances_without_graviton_trigger_schedule
  database = var.database
  sql      = local.ec2_instances_without_graviton_query

  capture "insert" {
    pipeline = pipeline.correct_ec2_instances_without_graviton
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ec2_instances_without_graviton" {
  title         = "Detect & correct EC2 instances without graviton"
  description   = "Detects EC2 instances without graviton processor and runs your chosen action."
  documentation = file("./pipelines/ec2/docs/detect_and_correct_ec2_instances_without_graviton.md")
  tags          = merge(local.ec2_common_tags, { class = "deprecated", recommended = "true" })

  param "database" {
    type        = connection.steampipe
    description = local.description_database
    default     = var.database
  }

  param "notifier" {
    type        = notifier
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ec2_instances_without_graviton_default_action
    enum        = local.ec2_instances_without_graviton_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_instances_without_graviton_enabled_actions
    enum        = local.ec2_instances_without_graviton_enabled_actions_enum
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ec2_instances_without_graviton_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ec2_instances_without_graviton
    args = {
      items              = step.query.detect.rows
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_ec2_instances_without_graviton" {
  title         = "Correct EC2 instances without graviton"
  description   = "Runs corrective action on a collection of EC2 instances without graviton processor."
  documentation = file("./pipelines/ec2/docs/correct_ec2_instances_without_graviton.md")
  tags          = merge(local.ec2_common_tags, { class = "deprecated", folder = "Internal" })

  param "items" {
    type = list(object({
      title       = string
      instance_id = string
      region      = string
      conn        = string
    }))
  }

  param "notifier" {
    type        = notifier
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ec2_instances_without_graviton_default_action
    enum        = local.ec2_instances_without_graviton_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_instances_without_graviton_enabled_actions
    enum        = local.ec2_instances_without_graviton_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected ${length(param.items)} EC2 instances without graviton processor."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.instance_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ec2_instance_without_graviton
    args = {
      title              = each.value.title
      instance_id        = each.value.instance_id
      region             = each.value.region
      conn               = connection.aws[each.value.conn]
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_one_ec2_instance_without_graviton" {
  title         = "Correct one EC2 instance without graviton"
  description   = "Runs corrective action on an EC2 instance without graviton processor."
  documentation = file("./pipelines/ec2/docs/correct_one_ec2_instance_without_graviton.md")
  tags          = merge(local.ec2_common_tags, { class = "deprecated", folder = "Internal" })

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

  param "conn" {
    type        = connection.aws
    description = local.description_connection
  }

  param "notifier" {
    type        = notifier
    description = local.description_notifier
    default     = var.notifier
  }

  param "notification_level" {
    type        = string
    description = local.description_notifier_level
    default     = var.notification_level
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.ec2_instances_without_graviton_default_action
    enum        = local.ec2_instances_without_graviton_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_instances_without_graviton_enabled_actions
    enum        = local.ec2_instances_without_graviton_enabled_actions_enum
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected EC2 Instance ${param.title} without graviton processor."
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
      actions = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.style_info
          pipeline_ref = detect_correct.pipeline.optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.level_verbose
            text     = "Skipped EC2 Instance ${param.title} without graviton processor."
          }
          success_msg = "Skipped EC2 Instance ${param.title}."
          error_msg   = "Error skipping EC2 Instance ${param.title}."
        },
        "stop_instance" = {
          label        = "Stop Instance"
          value        = "stop_instance"
          style        = local.style_alert
          pipeline_ref = aws.pipeline.stop_ec2_instances
          pipeline_args = {
            instance_ids = [param.instance_id]
            region       = param.region
            conn         = param.conn
          }
          success_msg = "Stopped EC2 Instance ${param.title}."
          error_msg   = "Error stopping EC2 Instance ${param.title}."
        }
        "terminate_instance" = {
          label        = "Terminate Instance"
          value        = "terminate_instance"
          style        = local.style_alert
          pipeline_ref = aws.pipeline.terminate_ec2_instances
          pipeline_args = {
            instance_ids = [param.instance_id]
            region       = param.region
            conn         = param.conn
          }
          success_msg = "Deleted EC2 Instance ${param.title}."
          error_msg   = "Error deleting EC2 Instance ${param.title}."
        }
      }
    }
  }
}