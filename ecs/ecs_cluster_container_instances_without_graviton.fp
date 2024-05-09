locals {
  ecs_cluster_container_instances_without_graviton_query = <<-EOQ
    select
      concat(ec2_instance_id, ' [', c.region, '/', c.account_id, ']') as title,
      c.cluster_arn,
      c.ec2_instance_id,
      c.region,
      c._ctx ->> 'connection_name' as cred
    from
      aws_ecs_container_instance as c
      left join aws_ec2_instance as i on c.ec2_instance_id = i.instance_id
    where
      i.platform != 'windows'
      and i.architecture != 'arm64';
  EOQ
}

trigger "query" "detect_and_correct_ecs_cluster_container_instances_without_graviton" {
  title       = "Detect & correct ECS cluster container instances without graviton processor"
  description = "Detects ECS cluster container instances without graviton processor and runs your chosen action."

  enabled  = var.ecs_cluster_container_instances_without_graviton_trigger_enabled
  schedule = var.ecs_cluster_container_instances_without_graviton_trigger_schedule
  database = var.database
  sql      = local.ecs_cluster_container_instances_without_graviton_query

  capture "insert" {
    pipeline = pipeline.correct_ecs_cluster_container_instances_without_graviton
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ecs_cluster_container_instances_without_graviton" {
  title         = "Detect & correct ECS cluster container instances without graviton processor"
  description   = "Detects ECS cluster container instances without graviton processor and runs your chosen action."
  // tags          = merge(local.ecs_common_tags, {
  //   class = "deprecated" 
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

  param "default_action" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.ecs_cluster_container_instance_without_graviton_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ecs_cluster_container_instance_without_graviton_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ecs_cluster_container_instances_without_graviton_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ecs_cluster_container_instances_without_graviton
    args     = {
      items                 = step.query.detect.rows
      notifier              = param.notifier
      notification_level    = param.notification_level
      approvers             = param.approvers
      default_action        = param.default_action
      enabled_actions       = param.enabled_actions
    }
  }
}

pipeline "correct_ecs_cluster_container_instances_without_graviton" {
  title         = "Corrects ECS cluster container instances without graviton processor"
  description   = "Runs corrective action on a collection of ECS cluster container instances without graviton processor."
  // tags          = merge(local.ecs_common_tags, { 
  //   class = "deprecated" 
  // })

  param "items" {
    type = list(object({
      title           = string
      cluster_arn     =string
      ec2_instance_id = string
      region          = string
      cred            = string
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
    default     = var.ecs_cluster_container_instance_without_graviton_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ecs_cluster_container_instance_without_graviton_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} ECS cluster container instances without graviton processor."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.ec2_instance_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_ecs_cluster_container_instance_without_graviton
    args            = {
      title                      = each.value.title
      ec2_instance_id            = each.value.ec2_instance_id
      cluster_arn                = each.value.cluster_arn
      region                     = each.value.region
      cred                       = each.value.cred
      notifier                   = param.notifier
      notification_level         = param.notification_level
      approvers                  = param.approvers
      default_action             = param.default_action
      enabled_actions            = param.enabled_actions
    }
  }
}

pipeline "correct_ecs_cluster_container_instance_without_graviton" {
  title         = "Correct an ECS cluster container instance without graviton processor"
  description   = "Runs corrective action on an ECS cluster container instance without graviton processor."
  // tags          = merge(local.ecs_common_tags, { class = "deprecated" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "ec2_instance_id" {
    type        = string
    description = "The ID of the ECS cluster container instance."
  }

  param "cluster_arn" {
    type        = string
    description = "The ARN of the ECS cluster."
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
    default     = var.ecs_cluster_container_instance_without_graviton_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ecs_cluster_container_instance_without_graviton_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args     = {
      notifier         = param.notifier
      notification_level   = param.notification_level
      approvers        = param.approvers
      detect_msg       = "Detected ECS Cluster Container Instance ${param.title} without graviton processor."
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
            text     = "Skipped ECS cluster container instance ${param.title} without graviton processor."
          }
          success_msg = "Skipped ECS Cluster Container Instance ${param.title}."
          error_msg   = "Error skipping ECS Cluster Container Instance ${param.title}."
        },
        "deregister_container_instance" = {
          label  = "Deregister Container Instance"
          value  = "deregister_container_instance"
          style  = local.StyleAlert
          pipeline_ref  = local.aws_pipeline_deregister_container_instances //TODO: Add pipeline
          pipeline_args = {
            cluster            = param.cluster_arn
            container_instance = param.ec2_instance_id
            region             = param.region
            cred               = param.cred
          }
          success_msg = "Deleted ECS Cluster Container Instance ${param.title}."
          error_msg   = "Error deleting ECS Cluster Container Instance ${param.title}."
        }
      }
    }
  }
}

pipeline "mock_aws_pipeline_deregister_container_instances" {

  param "cluster" {
    type        = string
  }

  param "container_instance" {
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