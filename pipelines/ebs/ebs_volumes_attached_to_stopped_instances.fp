locals {
  ebs_volumes_attached_to_stopped_instances_query = <<-EOQ
  with vols_and_instances as (
    select
      v.volume_id,
      i.instance_id,
      v.region,
      v.account_id,
      v._ctx,
      bool_or(i.instance_state = 'stopped') as has_stopped_instances
    from
      aws_ebs_volume as v
      left join jsonb_array_elements(v.attachments) as va on true
      left join aws_ec2_instance as i on va ->> 'InstanceId' = i.instance_id
    group by
      v.volume_id,
      i.instance_id,
      v.region,
      v.account_id,
      v._ctx
  )
  select
    concat(volume_id, ' [', volume_type, '/', region, '/', account_id, ']') as title,
    volume_id,
    region,
    _ctx ->> 'connection_name' as cred
  from
    vols_and_instances
  where
    has_stopped_instances = true;
  EOQ
}

trigger "query" "detect_and_correct_ebs_volumes_attached_to_stopped_instances" {
  title         = "Detect & correct EBS volumes attached to stopped instances"
  description   = "Detects EBS volumes attached to stopped instances and runs your chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_volumes_attached_to_stopped_instances_trigger.md")
  tags          = merge(local.ebs_common_tags, { class = "unused" })

  enabled  = var.ebs_volumes_attached_to_stopped_instances_trigger_enabled
  schedule = var.ebs_volumes_attached_to_stopped_instances_trigger_schedule
  database = var.database
  sql      = local.ebs_volumes_attached_to_stopped_instances_query

  capture "insert" {
    pipeline = pipeline.correct_ebs_volumes_attached_to_stopped_instances
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ebs_volumes_attached_to_stopped_instances" {
  title         = "Detect & correct EBS volumes attached to stopped instances"
  description   = "Detects EBS volumes attached to stopped instances and runs your chosen action."
  documentation = file("./pipelines/ebs/docs/detect_and_correct_ebs_volumes_attached_to_stopped_instances.md")
  tags          = merge(local.ebs_common_tags, { class = "unused", recommended = "true" })

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
    default     = var.ebs_volumes_attached_to_stopped_instances_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_attached_to_stopped_instances_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_volumes_attached_to_stopped_instances_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ebs_volumes_attached_to_stopped_instances
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

pipeline "correct_ebs_volumes_attached_to_stopped_instances" {
  title         = "Correct EBS volumes attached to stopped instances"
  description   = "Runs corrective action on a collection of EBS volumes attached to stopped instances."
  documentation = file("./pipelines/ebs/docs/correct_ebs_volumes_attached_to_stopped_instances.md")
  tags          = merge(local.ebs_common_tags, { class = "unused" })

  param "items" {
    type = list(object({
      title     = string
      volume_id = string
      region    = string
      cred      = string
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
    default     = var.ebs_volumes_attached_to_stopped_instances_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_attached_to_stopped_instances_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EBS volumes attached to stopped instances."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.volume_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_ebs_volume_attached_to_stopped_instance
    args = {
      title              = each.value.title
      volume_id          = each.value.volume_id
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

pipeline "correct_one_ebs_volume_attached_to_stopped_instance" {
  title         = "Correct one EBS volume attached to stopped instance"
  description   = "Runs corrective action on an EBS volume attached to a stopped instance."
  documentation = file("./pipelines/ebs/docs/correct_one_ebs_volume_attached_to_stopped_instance.md")
  tags          = merge(local.ebs_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "volume_id" {
    type        = string
    description = "The ID of the EBS volume."
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
    default     = var.ebs_volumes_attached_to_stopped_instances_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.ebs_volumes_attached_to_stopped_instances_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected EBS volume ${param.title} attached to stopped instance."
      default_action     = param.default_action
      enabled_actions    = param.enabled_actions
      actions = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.style_info
          pipeline_ref = local.pipeline_optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.level_verbose
            text     = "Skipped EBS volume ${param.title} attached to stopped instance."
          }
          success_msg = ""
          error_msg   = ""
        },
        "detach_volume" = {
          label        = "Detach Volume"
          value        = "detach_volume"
          style        = local.style_info
          pipeline_ref = local.aws_pipeline_detach_ebs_volume
          pipeline_args = {
            volume_id = param.volume_id
            region    = param.region
            cred      = param.cred
          }
          success_msg = "Detached EBS volume ${param.title} from the instance."
          error_msg   = "Error detaching EBS volume ${param.title} from the instance."
        },
        "delete_volume" = {
          label        = "Delete Volume"
          value        = "delete_volume"
          style        = local.style_alert
          pipeline_ref = local.aws_pipeline_delete_ebs_volume
          pipeline_args = {
            volume_id = param.volume_id
            region    = param.region
            cred      = param.cred
          }
          success_msg = "Deleted EBS Volume ${param.title}."
          error_msg   = "Error deleting EBS Volume ${param.title}."
        }
        "snapshot_and_delete_volume" = {
          label        = "Snapshot & Delete Volume"
          value        = "snapshot_and_delete_volume"
          style        = local.style_alert
          pipeline_ref = pipeline.snapshot_and_delete_ebs_volume
          pipeline_args = {
            volume_id = param.volume_id
            region    = param.region
            cred      = param.cred
          }
          success_msg = "Snapshotted & Deleted EBS Volume ${param.title}."
          error_msg   = "Error snapshotting & deleting EBS Volume ${param.title}."
        }
      }
    }
  }
}

pipeline "snapshot_and_delete_ebs_volume" {
  title       = "Snapshot & Delete EBS Volume"
  description = "A utility pipeline which snapshots and deletes an EBS volume."

  param "region" {
    type        = string
    description = local.description_region
  }

  param "cred" {
    type        = string
    description = local.description_credential
  }

  param "volume_id" {
    type        = string
    description = "The ID of the EBS volume."
  }

  step "pipeline" "create_ebs_snapshot" {
    pipeline = local.aws_pipeline_create_ebs_snapshot
    args = {
      region    = param.region
      cred      = param.cred
      volume_id = param.volume_id
    }
  }

  step "pipeline" "delete_ebs_volume" {
    depends_on = [step.pipeline.create_ebs_snapshot]
    pipeline   = local.aws_pipeline_delete_ebs_volume
    args = {
      region    = param.region
      cred      = param.cred
      volume_id = param.volume_id
    }
  }
}

variable "ebs_volumes_attached_to_stopped_instances_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_attached_to_stopped_instances_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_attached_to_stopped_instances_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  tags = {
    folder = "Advanced/EBS"
  }
}

variable "ebs_volumes_attached_to_stopped_instances_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "detach_volume", "delete_volume", "snapshot_and_delete_volume"]
  tags = {
    folder = "Advanced/EBS"
  }
}
