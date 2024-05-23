locals {
  ec2_instances_with_low_utilization_query = <<-EOQ
    with ec2_instance_utilization as (
      select
        instance_id,
        max(average) as avg_max,
        count(average) days
      from
        aws_ec2_instance_metric_cpu_utilization_daily
      where
        date_part('day', now() - timestamp) <= 30
      group by
        instance_id
      having max(average) < ${var.ec2_instances_with_low_utilization_avg_cpu_utilization}
    )
    ,ec2_instance_current as (
      select
        i.title,
        i.instance_id,
        i.instance_type,
        i.region,
        i.account_id,
        i._ctx->'connection_name' as cred,
        split_part(i.instance_type, '.', 1) as instance_family
      from
        ec2_instance_utilization u
      left join
        aws_ec2_instance i
      on
        u.instance_id = i.instance_id
    )
    ,distinct_families as (
      select distinct instance_family from ec2_instance_current
    )
    ,family_details as (
      select
        instance_family,
        instance_type,
        rank() over (
          partition by instance_family
          order by (v_cpu_info->'DefaultVCpus')::int asc, (memory_info->'SizeInMiB')::bigint asc
        ) as weight
      from distinct_families
      join aws_ec2_instance_type on instance_type like instance_family || '.%'
    )
    select
      concat(instance_id,' (', title, ') [', instance_type, '/', region, '/', account_id, ']') as title,
      instance_id,
      instance_type as current_type,
      coalesce((
        select instance_type
        from family_details fd
        where
          fd.instance_family = c.instance_family
        and
          fd.weight < (select weight from family_details where instance_type = c.instance_type)
        order by fd.weight desc
        limit 1),'') as suggested_type,
      region,
      cred
    from ec2_instance_current c;
  EOQ
}

trigger "query" "detect_and_correct_ec2_instances_with_low_utilization" {
  title         = "Detect & correct EC2 instances with low utilization"
  description   = "Detects EC2 instances with low utilization and runs your chosen action."
  documentation = file("./ec2/docs/detect_and_correct_ec2_instances_with_low_utilization_trigger.md")
  tags          = merge(local.ec2_common_tags, { class = "unused" })

  enabled  = var.ec2_instances_with_low_utilization_trigger_enabled
  schedule = var.ec2_instances_with_low_utilization_trigger_schedule
  database = var.database
  sql      = local.ec2_instances_with_low_utilization_query

  capture "insert" {
    pipeline = pipeline.correct_ec2_instances_with_low_utilization
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ec2_instances_with_low_utilization" {
  title         = "Detect & correct EC2 instances with low utilization"
  description   = "Detects EC2 instances with low utilization and runs your chosen action."
  documentation = file("./ec2/docs/detect_and_correct_ec2_instances_with_low_utilization.md")
  tags          = merge(local.ec2_common_tags, { class = "unused", type = "featured" })

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
    default     = var.ec2_instances_with_low_utilization_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_instances_with_low_utilization_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ec2_instances_with_low_utilization_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ec2_instances_with_low_utilization
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

pipeline "correct_ec2_instances_with_low_utilization" {
  title         = "Correct EC2 instances with low utilization"
  description   = "Corrects EC2 instances with low utilization based on the chosen action."
  documentation = file("./ec2/docs/correct_ec2_instances_with_low_utilization.md")
  tags          = merge(local.ec2_common_tags, { class = "unused" })

  param "items" {
    type = list(object({
      title          = string
      instance_id    = string
      current_type   = string
      suggested_type = string
      region         = string
      cred           = string
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
    default     = var.ec2_instances_with_low_utilization_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_instances_with_low_utilization_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EC2 instances without graviton processor."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.instance_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ec2_instance_with_low_utilization
    args = {
      title              = each.value.title
      instance_id        = each.value.instance_id
      current_type       = each.value.current_type
      suggested_type     = each.value.suggested_type
      region             = each.value.region
      cred               = each.value.cred
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
    }
  }
}

pipeline "correct_one_ec2_instance_with_low_utilization" {
  title         = "Correct one EC2 instance with low utilization"
  description   = "Runs corrective action on a single EC2 instance with low utilization."
  documentation = file("./ec2/docs/correct_one_ec2_instance_with_low_utilization.md")
  tags          = merge(local.ec2_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "instance_id" {
    type        = string
    description = "The ID of the EC2 instance."
  }

  param "current_type" {
    type        = string
    description = "The current EC2 instance type."
  }

  param "suggested_type" {
    type        = string
    description = "The suggested EC2 instance type."
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
    default     = var.ec2_instances_with_low_utilization_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ec2_instances_with_low_utilization_enabled_actions
  }

  step transform "build_non_optional_actions" {
    value = {
      "skip" = {
        label        = "Skip"
        value        = "skip"
        style        = local.style_info
        pipeline_ref = local.pipeline_optional_message
        pipeline_args = {
          notifier = param.notifier
          send     = param.notification_level == local.level_verbose
          text     = "Skipped EC2 instance ${param.title} with low utilization."
        }
        success_msg = "Skipping EC2 instance ${param.title}."
        error_msg   = "Error skipping EC2 instance ${param.title}."
      },
      "stop_instance" = {
        label        = "Stop Instance"
        value        = "stop_instance"
        style        = local.style_alert
        pipeline_ref = local.aws_pipeline_stop_ec2_instances
        pipeline_args = {
          instance_ids = [param.instance_id]
          region       = param.region
          cred         = param.cred
        }
        success_msg = "Stopped EC2 instance ${param.title}."
        error_msg   = "Error stopping EC2 instance ${param.title}."
      }
    }
  }

  step "transform" "build_all_actions" {
    value = merge(
      step.transform.build_non_optional_actions.value,
      param.suggested_type == "" ? {} : {
        "update_instance_type" = {
          label        = "Update to ${param.suggested_type}"
          value        = "update_instance_type"
          style        = local.style_ok
          pipeline_ref = local.aws_pipeline_update_ec2_instance_type
          pipeline_args = {
            instance_id   = param.instance_id
            instance_type = param.suggested_type
            region        = param.region
            cred          = param.cred
          }
          success_msg = "Updated EC2 instance ${param.title} from ${param.current_type} to ${param.suggested_type}."
          error_msg   = "Error updating EC2 instance ${param.title} type to ${param.suggested_type}."
        }
      }
    )
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected EC2 instance ${param.title} with low utilization."
      default_action     = param.default_action
      enabled_actions    = [for action in param.enabled_actions : action if contains(keys(step.transform.build_all_actions.value), action)]
      actions            = step.transform.build_all_actions.value
    }
  }
}

variable "ec2_instances_with_low_utilization_avg_cpu_utilization" {
  type        = number
  default     = 20
  description = "The average CPU utilization below which an instance is considered to have low utilization."
}

variable "ec2_instances_with_low_utilization_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
}

variable "ec2_instances_with_low_utilization_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
}

variable "ec2_instances_with_low_utilization_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
}

variable "ec2_instances_with_low_utilization_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "stop_instance", "update_instance_type"]
}

pipeline "mock_update_ec2_instance_type" {
  param "instance_id" {
    type = string
  }

  param "instance_type" {
    type = string
  }

  param "region" {
    type = string
  }

  param "cred" {
    type = string
  }

  step "transform" "mock" {
    value = "Mocked update EC2 instance type for ${param.instance_id} to ${param.instance_type}."
  }
}