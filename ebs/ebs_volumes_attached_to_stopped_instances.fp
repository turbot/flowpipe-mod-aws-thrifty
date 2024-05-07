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
  concat(volume_id, ' [', region, '/', account_id, ']') as title,
  volume_id,
  region,
  _ctx ->> 'connection_name' as cred
from
  vols_and_instances
where
  has_stopped_instances = true;
  EOQ
}

trigger "query" "detect_and_respond_to_ebs_volumes_attached_to_stopped_instances" {
  title       = "Detect and respond to EBS volumes attached to stopped instances"
  description = "Detects EBS volumes which are attached to stopped instances and responds with your chosen action."

  enabled  = var.ebs_volumes_attached_to_stopped_instances_trigger_enabled
  schedule = var.ebs_volumes_attached_to_stopped_instances_trigger_schedule
  database = var.database
  sql      = local.ebs_volumes_attached_to_stopped_instances_query

  capture "insert" {
    pipeline = pipeline.respond_to_ebs_volumes_attached_to_stopped_instances
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_ebs_volumes_attached_to_stopped_instances" {
  title       = "Detect and respond to EBS volumes attached to stopped instances"
  description = "Detects EBS volumes which are attached to stopped instances and responds with your chosen action."
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
    default     = var.ebs_volumes_attached_to_stopped_instances_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volumes_attached_to_stopped_instances_enabled_response_options
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ebs_volumes_attached_to_stopped_instances_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_ebs_volumes_attached_to_stopped_instances
    args = {
      items                    = step.query.detect.rows
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
    }
  }
}

pipeline "respond_to_ebs_volumes_attached_to_stopped_instances" {
  title       = "Respond to EBS volumes attached to stopped instances"
  description = "Responds to a collection of EBS volumes which are attached to stopped instances."
  // tags          = merge(local.ebs_common_tags, { class = "deprecated" })

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
    default     = var.ebs_volumes_attached_to_stopped_instances_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volumes_attached_to_stopped_instances_enabled_response_options
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EBS volumes attached to stopped instances."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.volume_id => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_ebs_volume_attached_to_stopped_instance
    args = {
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

pipeline "respond_to_ebs_volume_attached_to_stopped_instance" {
  title       = "Respond to EBS volume attached to stopped instance"
  description = "Responds to an EBS volume attached to stopped instance."
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
    default     = var.ebs_volumes_attached_to_stopped_instances_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ebs_volumes_attached_to_stopped_instances_enabled_response_options
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected EBS volume ${param.title} attached to stopped instance."
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
      response_options = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.StyleInfo
          pipeline_ref = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped EBS volume ${param.title} attached to stopped instance."
          }
          success_msg = ""
          error_msg   = ""
        },
        "detach_volume" = {
          label        = "Detach Volume"
          value        = "detach_volume"
          style        = local.StyleOk
          pipeline_ref = pipeline.mock_aws_pipeline_detach_ebs_volume // TODO: Swap to local.aws_pipeline_detach_ebs_volume when added to library mod
          pipeline_args = {
            volume_id = param.volume_id
            region    = param.region
            cred      = param.cred
          }
          success_msg = "Detached EBS volume ${param.title} from the instance."
          error_msg   = "Error detaching EBS volume ${param.title} from the instance."
        }
        "delete_volume" = {
          label        = "Delete_volume"
          value        = "delete_volume"
          style        = local.StyleAlert
          pipeline_ref = pipeline.mock_aws_pipeline_delete_ebs_volume // TODO: Swap to local.aws_pipeline_delete_ebs_volume when added to library mod
          pipeline_args = {
            volume_id = param.volume_id
            region    = param.region
            cred      = param.cred
          }
          success_msg = "Deleted EBS Volume ${param.title}."
          error_msg   = "Error deleting EBS Volume ${param.title}."
        }
      }
    }
  }
}

pipeline "mock_aws_pipeline_detach_ebs_volume" {
  param "volume_id" {
    type        = string
  }

  param "region" {
    type        = string
  }

  param "cred" {
    type        = string
  }

  output "result" {
    value = "Mocked: Detach EBS Volume [VolumeID: ${param.volume_id}, Region: ${param.region}, Cred: ${param.cred}]"
  }
}
