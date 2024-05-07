locals {
  emr_clusters_idle_30_mins_query = <<-EOQ
    with cluster_metrics as (
      select
        id,
        maximum,
        date(timestamp) as timestamp
      from
        aws_emr_cluster_metric_is_idle
      where
        timestamp <= current_timestamp - interval '30 minutes'
    ),
    emr_cluster_isidle as (
      select
        id,
        count(maximum) as count,
        sum(maximum)/count(maximum) as avagsum
      from
        cluster_metrics
      group by id, timestamp
    )
    select
      concat(i.id, ' [', i.region, '/', i.account_id, ']') as title,
      i.id,
      i.region,
      i._ctx ->> 'connection_name' as cred
    from
      aws_emr_cluster as i
      left join emr_cluster_isidle as u on u.id = i.id
    where
      u.id is null
      and  avagsum = 1 and count >= 7;
  EOQ
}

trigger "query" "detect_and_respond_to_emr_clusters_idle_30_mins" {
  title       = "Detect and respond EMR clusters idle for more than 30 mins"
  description = "Detects EMR clusters idle for more than 30 mins and responds with your chosen action."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = local.emr_clusters_idle_30_mins_query

  capture "insert" {
    pipeline = pipeline.respond_to_emr_clusters_idle_30_mins
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_emr_clusters_idle_30_mins" {
  title         = "Detect and respond EMR clusters idle for more than 30 mins"
  description   = "Detects EMR clusters idle for more than 30 mins and responds with your chosen action."
  // tags          = merge(local.emr_common_tags, {
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
    default     = var.emr_cluster_idle_30_mins_default_action
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.emr_cluster_idle_30_mins_enabled_response_options
  }

  step "query" "detect" {
    database = param.database
    sql      = local.emr_clusters_idle_30_mins_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_emr_clusters_idle_30_mins
    args     = {
      items                     = step.query.detect.rows
      notifier                  = param.notifier
      notification_level        = param.notification_level
      approvers                 = param.approvers
      default_response_option   = param.default_response_option
      enabled_response_options  = param.enabled_response_options
    }
  }
}

pipeline "respond_to_emr_clusters_idle_30_mins" {
  title         = "Respond to EMR clusters of previous generation instances"
  description   = "Responds to a collection of EMR clusters of previous generation instances."
  // tags          = merge(local.emr_common_tags, { 
  //   class = "unused" 
  // })

  param "items" {
    type = list(object({
      title       = string
      id          = string
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
    default     = var.emr_cluster_idle_30_mins_default_action
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.emr_cluster_idle_30_mins_enabled_response_options
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EMR clusters idle for more than 30 mins."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.id => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_emr_cluster_idle_30_mins
    args            = {
      title                      = each.value.title
      id                         = each.value.id
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

pipeline "respond_to_emr_cluster_idle_30_mins" {
  title         = "Respond to EMR cluster idle for more than 30 mins"
  description   = "Responds to an EMR cluster idle for more than 30 mins."
  // tags          = merge(local.emr_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "id" {
    type        = string
    description = "The ID of the EMR cluster."
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
    default     = var.emr_cluster_idle_30_mins_default_action
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.emr_cluster_idle_30_mins_enabled_response_options
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args     = {
      notifier                  = param.notifier
      notification_level        = param.notification_level
      approvers                 = param.approvers
      detect_msg                = "Detected EMR Cluster ${param.title} idle for more than 30 mins"
      default_response_option   = param.default_response_option
      enabled_response_options  = param.enabled_response_options
      response_options = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.StyleInfo
          pipeline_ref  = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped EMR Cluster ${param.title}."
          }
          success_msg = "Skipped EMR Cluster ${param.title}."
          error_msg   = "Error skipping EMR Cluster ${param.title}."
        },
        "stop_cluster" = {
          label  = "Stop Cluster"
          value  = "stop_cluster"
          style  = local.StyleAlert
          // pipeline_ref  = local.aws_pipeline_stop_emr_clusters // TODO: Add pipeline
          // pipeline_args = {
          //   cluster_ids = [param.id]
          //   region       = param.region
          //   cred         = param.cred
          // }
          success_msg = "Stopped EMR Cluster ${param.title}."
          error_msg   = "Error stopping EMR Cluster ${param.title}."
        }
        "delete_cluster" = {
          label  = "Terminate Cluster"
          value  = "delete_cluster"
          style  = local.StyleAlert
          // pipeline_ref  = local.aws_pipeline_terminate_emr_clusters // TODO: Add pipeline
          // pipeline_args = {
          //   cluster_ids = [param.id]
          //   region       = param.region
          //   cred         = param.cred
          // }
          success_msg = "Deleted EMR Cluster ${param.title}."
          error_msg   = "Error deleting EMR Cluster ${param.title}."
        }
      }
    }
  }
}