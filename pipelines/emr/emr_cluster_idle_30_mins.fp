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
      i.sp_connection_name as conn
    from
      aws_emr_cluster as i
      left join emr_cluster_isidle as u on u.id = i.id
    where
      u.id is null
      and  avagsum = 1 and count >= 7;
  EOQ

  emr_clusters_idle_30_mins_default_action_enum  = ["notify", "skip", "delete_cluster"]
  emr_clusters_idle_30_mins_enabled_actions_enum = ["skip", "delete_cluster"]
}

// Variable definitions

variable "emr_clusters_idle_30_mins_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/EMR"
  }
}

variable "emr_clusters_idle_30_mins_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/EMR"
  }
}

variable "emr_clusters_idle_30_mins_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "delete_cluster"]
  tags = {
    folder = "Advanced/EMR"
  }
}

variable "emr_clusters_idle_30_mins_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_cluster"]
  enum        = ["skip", "delete_cluster"]
  tags = {
    folder = "Advanced/EMR"
  }
}

trigger "query" "detect_and_correct_emr_clusters_idle_30_mins" {
  title         = "Detect & correct EMR Clusters idle 30 mins"
  description   = "Detects EMR clusters idle for more than 30 mins and runs your chosen action."
  documentation = file("./pipelines/emr/docs/detect_and_correct_emr_clusters_idle_30_mins_trigger.md")
  tags          = merge(local.emr_common_tags, { class = "unused" })

  enabled  = var.emr_clusters_idle_30_mins_trigger_enabled
  schedule = var.emr_clusters_idle_30_mins_trigger_schedule
  database = var.database
  sql      = local.emr_clusters_idle_30_mins_query

  capture "insert" {
    pipeline = pipeline.correct_emr_clusters_idle_30_mins
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_emr_clusters_idle_30_mins" {
  title         = "Detect & correct EMR Clusters idle 30 mins"
  description   = "Detects EMR clusters idle for more than 30 mins and runs your chosen action."
  documentation = file("./pipelines/emr/docs/detect_and_correct_emr_clusters_idle_30_mins.md")
  tags          = merge(local.emr_common_tags, { class = "unused", recommended = "true" })

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
    enum        = local.notification_level_enum
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.emr_clusters_idle_30_mins_default_action
    enum        = local.emr_clusters_idle_30_mins_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.emr_clusters_idle_30_mins_enabled_actions
    enum        = local.emr_clusters_idle_30_mins_enabled_actions_enum
  }

  step "query" "detect" {
    database = param.database
    sql      = local.emr_clusters_idle_30_mins_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_emr_clusters_idle_30_mins
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

pipeline "correct_emr_clusters_idle_30_mins" {
  title         = "Correct EMR Clusters idle 30 mins"
  description   = "Runs corrective action on a collection of EMR clusters idle for more than 30 mins."
  documentation = file("./pipelines/emr/docs/correct_emr_clusters_idle_30_mins.md")
  tags          = merge(local.emr_common_tags, { class = "unused", folder = "Internal" })

  param "items" {
    type = list(object({
      title  = string
      id     = string
      region = string
      conn   = string
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
    enum        = local.notification_level_enum
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.emr_clusters_idle_30_mins_default_action
    enum        = local.emr_clusters_idle_30_mins_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.emr_clusters_idle_30_mins_enabled_actions
    enum        = local.emr_clusters_idle_30_mins_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected ${length(param.items)} EMR clusters idle for more than 30 mins."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_emr_cluster_idle_30_mins
    args = {
      title              = each.value.title
      id                 = each.value.id
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

pipeline "correct_one_emr_cluster_idle_30_mins" {
  title         = "Correct one EMR Cluster idle 30 mins"
  description   = "Runs corrective action on an EMR cluster idle for more than 30 mins."
  documentation = file("./pipelines/emr/docs/correct_one_emr_cluster_idle_30_mins.md")
  tags          = merge(local.emr_common_tags, { class = "unused", folder = "Internal" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "id" {
    type        = string
    description = "The ID of the EMR cluster."
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
    enum        = local.notification_level_enum
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.emr_clusters_idle_30_mins_default_action
    enum        = local.emr_clusters_idle_30_mins_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.emr_clusters_idle_30_mins_enabled_actions
    enum        = local.emr_clusters_idle_30_mins_enabled_actions_enum
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier           = param.notifier
      notification_level = param.notification_level
      approvers          = param.approvers
      detect_msg         = "Detected EMR cluster ${param.title} idle for more than 30 mins"
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
            text     = "Skipped EMR cluster ${param.title}."
          }
          success_msg = "Skipped EMR cluster ${param.title}."
          error_msg   = "Error skipping EMR cluster ${param.title}."
        },
        "delete_cluster" = {
          label        = "Delete Cluster"
          value        = "delete_cluster"
          style        = local.style_alert
          pipeline_ref = aws.pipeline.terminate_emr_clusters
          pipeline_args = {
            cluster_ids = [param.id]
            region      = param.region
            conn        = param.conn
          }
          success_msg = "Deleted EMR cluster ${param.title}."
          error_msg   = "Error deleting EMR cluster ${param.title}."
        }
      }
    }
  }
}

