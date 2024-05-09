locals {
  ecs_service_without_autoscaling_query = <<-EOQ
    with service_with_autoscaling as (
      select
        distinct split_part(t.resource_id, '/', 2) as cluster_name,
        split_part(t.resource_id, '/', 3) as service_name
      from
        aws_appautoscaling_target as t
      where
        t.service_namespace = 'ecs'
    )
    select
      concat(s.service_name, ' [', s.region, '/', s.account_id, ']') as title,
      s.cluster_arn,
      s.service_name,
      region,
      _ctx ->> 'connection_name' as cred
    from
      aws_ecs_service as s
      left join service_with_autoscaling as a on s.service_name = a.service_name and a.cluster_name = split_part(s.cluster_arn, '/', 2)
    where
      s.launch_type != 'FARGATE'
      and a.service_name is null;
  EOQ
}

trigger "query" "detect_and_correct_ecs_services_without_autoscaling" {
  title       = "Detect & correct ECS services without autoscaling"
  description = "Detects ECS services without autoscaling and runs your chosen action."

  enabled  = var.ecs_service_without_autoscaling_trigger_enabled
  schedule = var.ecs_service_without_autoscaling_trigger_schedule
  database = var.database
  sql      = local.ecs_service_without_autoscaling_query

  capture "insert" {
    pipeline = pipeline.correct_ecs_service_without_autoscaling
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_ecs_services_without_autoscaling" {
  title         = "Detect & correct ECS services without autoscaling"
  description   = "Detects ECS services without autoscaling and runs your chosen action."
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
    default     = var.ecs_service_without_autoscaling_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ecs_service_without_autoscaling_enabled_actions
  }

  step "query" "detect" {
    database = param.database
    sql      = local.ecs_service_without_autoscaling_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_ecs_service_without_autoscaling
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

pipeline "correct_ecs_services_without_autoscaling" {
  title         = "Corrects ECS services without autoscaling"
  description   = "Runs corrective action on a collection of ECS services without autoscaling."
  // tags          = merge(local.ecs_common_tags, { 
  //   class = "deprecated" 
  // })

  param "items" {
    type = list(object({
      title           = string
      cluster_arn     = string
      service_name    = string
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
    default     = var.ecs_service_without_autoscaling_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ecs_service_without_autoscaling_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} ECS services without autoscaling."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.ec2_instance_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_ecs_service_without_autoscaling
    args            = {
      title                      = each.value.title
      service_name               = each.value.service_name
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

pipeline "correct_one_ecs_service_without_autoscaling" {
  title         = "Correct one ECS service without autoscaling"
  description   = "Runs corrective action on an ECS service without autoscaling."
  // tags          = merge(local.ecs_common_tags, { class = "deprecated" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "service_name" {
    type        = string
    description = "The name of the ECS service."
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
    default     = var.ecs_service_without_autoscaling_default_action
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.ecs_service_without_autoscaling_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args     = {
      notifier         = param.notifier
      notification_level   = param.notification_level
      approvers        = param.approvers
      detect_msg       = "Detected ECS Services ${param.title} without autoscaling."
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
            text     = "Skipped ECS cluster container instance ${param.title} without autoscaling."
          }
          success_msg = "Skipped ECS Services ${param.title}."
          error_msg   = "Error skipping ECS Services ${param.title}."
        },
        "delete_service" = {
          label  = "Delete ECS Service"
          value  = "delete_service"
          style  = local.StyleAlert
          pipeline_ref  = local.mock_aws_pipeline_delete_ecs_service //TODO: Add pipeline
          pipeline_args = {
            cluster            = param.cluster_arn
            service_name       = param.service_name
            region             = param.region
            cred               = param.cred
          }
          success_msg = "Deleted ECS Services ${param.title}."
          error_msg   = "Error deleting ECS Services ${param.title}."
        }
      }
    }
  }
}

pipeline "mock_aws_pipeline_delete_ecs_service" {

  param "cluster" {
    type        = string
  }

  param "service_name" {
    type        = string
  }

  param "region" {
    type        = string
  }

  param "cred" {
    type        = string
  }

  output "result" {
    value = "Mocked: Delete ECS Service [ServiceName: ${param.service_name}, Region: ${param.region}, Cred: ${param.cred}]"
  }
}