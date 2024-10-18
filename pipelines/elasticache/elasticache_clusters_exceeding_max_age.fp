
locals {
  elasticache_clusters_exceeding_max_age_query = <<-EOQ
    with filter_clusters as (
    select
      distinct c.replication_group_id as name,
      c.cache_cluster_create_time,
      c.sp_connection_name,
      c.region,
      c.account_id,
      'redis' as engine,
      c.partition
    from
      aws_elasticache_replication_group as rg
      left join aws_elasticache_cluster as c on rg.replication_group_id = c.replication_group_id
    union
    select
      cache_cluster_id as name,
      cache_cluster_create_time,
      sp_connection_name,
      region,
      account_id,
      engine,
      partition
    from
      aws_elasticache_cluster
    where
      engine = 'memcached'
  )
  select
    concat(name, ' [', region, '/', account_id, ']') as title,
    name,
    region,
    account_id,
    sp_connection_name as conn
  from
    filter_clusters
  where
    date_part('day', now() - cache_cluster_create_time) > ${var.elasticache_clusters_exceeding_max_age_days};
  EOQ

  elasticache_clusters_exceeding_max_age_default_action_enum  = ["notify", "skip", "delete_cluster"]
  elasticache_clusters_exceeding_max_age_enabled_actions_enum = ["skip", "delete_cluster"]
}

variable "elasticache_clusters_exceeding_max_age_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/ElastiCache"
  }
}

variable "elasticache_clusters_exceeding_max_age_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/ElastiCache"
  }
}

variable "elasticache_clusters_exceeding_max_age_days" {
  type        = number
  description = "The maximum number of days Elasticache clusters can be retained."
  default     = 90
  tags = {
    folder = "Advanced/ElastiCache"
  }
}

variable "elasticache_clusters_exceeding_max_age_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "delete_cluster"]
  tags = {
    folder = "Advanced/ElastiCache"
  }
}

variable "elasticache_clusters_exceeding_max_age_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_cluster"]
  enum        = ["skip", "delete_cluster"]
  tags = {
    folder = "Advanced/ElastiCache"
  }
}

trigger "query" "detect_and_correct_elasticache_clusters_exceeding_max_age" {
  title         = "Detect & correct Elasticache clusters exceeding max age"
  description   = "Detects Elasticache clusters exceeding max age and responds with your chosen action."
  documentation = file("./pipelines/elasticache/docs/detect_and_correct_elasticache_clusters_exceeding_max_age_trigger.md")
  tags          = merge(local.elasticache_common_tags, { class = "managed" })

  enabled  = var.elasticache_clusters_exceeding_max_age_trigger_enabled
  schedule = var.elasticache_clusters_exceeding_max_age_trigger_schedule
  database = var.database
  sql      = local.elasticache_clusters_exceeding_max_age_query

  capture "insert" {
    pipeline = pipeline.correct_elasticache_clusters_exceeding_max_age
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_elasticache_clusters_exceeding_max_age" {
  title         = "Detect & correct Elasticache clusters exceeding max age"
  description   = "Detects Elasticache clusters exceeding max age and responds with your chosen action."
  documentation = file("./pipelines/elasticache/docs/detect_and_correct_elasticache_clusters_exceeding_max_age.md")
  tags          = merge(local.elasticache_common_tags, { class = "managed", recommended = "true" })

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
    default     = var.elasticache_clusters_exceeding_max_age_default_action
    enum        = local.elasticache_clusters_exceeding_max_age_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.elasticache_clusters_exceeding_max_age_enabled_actions
    enum        = local.elasticache_clusters_exceeding_max_age_enabled_actions_enum
  }

  step "query" "detect" {
    database = param.database
    sql      = local.elasticache_clusters_exceeding_max_age_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_elasticache_clusters_exceeding_max_age
    args = {
      items                    = step.query.detect.rows
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
    }
  }
}

pipeline "correct_elasticache_clusters_exceeding_max_age" {
  title         = "Correct Elasticache clusters exceeding max age"
  description   = "Runs corrective action on a collection of Elasticache clusters exceeding max age."
  documentation = file("./pipelines/elasticache/docs/correct_elasticache_clusters_exceeding_max_age.md")
  tags          = merge(local.elasticache_common_tags, { class = "managed", folder = "Internal" })

  param "items" {
    type = list(object({
      title  = string
      name   = string
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
  }

  param "approvers" {
    type        = list(notifier)
    description = local.description_approvers
    default     = var.approvers
  }

  param "default_action" {
    type        = string
    description = local.description_default_action
    default     = var.elasticache_clusters_exceeding_max_age_default_action
    enum        = local.elasticache_clusters_exceeding_max_age_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.elasticache_clusters_exceeding_max_age_enabled_actions
    enum        = local.elasticache_clusters_exceeding_max_age_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected ${length(param.items)} Elasticache Clusters exceeding maximum age."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.name => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_elasticache_cluster_exceeding_max_age
    args = {
      title                    = each.value.title
      name                     = each.value.name
      region                   = each.value.region
      conn                     = connection.aws[each.value.conn]
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
    }
  }
}

pipeline "correct_one_elasticache_cluster_exceeding_max_age" {
  title         = "Correct one Elasticache cluster exceeding max age"
  description   = "Runs corrective action on an Elasticache cluster exceeding max age."
  documentation = file("./pipelines/elasticache/docs/correct_one_elasticache_cluster_exceeding_max_age.md")
  tags          = merge(local.elasticache_common_tags, { class = "managed", folder = "Internal" })

  param "title" {
    type        = string
    description = local.description_title
  }

  param "name" {
    type        = string
    description = "The ID of the Elasticache cluster."
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
    default     = var.elasticache_clusters_exceeding_max_age_default_action
    enum        = local.elasticache_clusters_exceeding_max_age_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.elasticache_clusters_exceeding_max_age_enabled_actions
    enum        = local.elasticache_clusters_exceeding_max_age_enabled_actions_enum
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected Elasticache Cluster ${param.title} exceeding maximum age."
      default_action  = param.default_action
      enabled_actions = param.enabled_actions
      response_options = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.style_info
          pipeline_ref = detect_correct.pipeline.optional_message
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.level_verbose
            text     = "Skipped Elasticache Cluster ${param.title} exceeding maximum age."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete_cluster" = {
          label        = "Delete Cluster"
          value        = "delete_cluster"
          style        = local.style_alert
          pipeline_ref = aws.pipeline.delete_elasticache_cluster
          pipeline_args = {
            cache_cluster_id = param.name
            region           = param.region
            conn             = param.conn
          }
          success_msg = "Deleted Elasticache Cluster ${param.title}."
          error_msg   = "Error deleting Elasticache Cluster ${param.title}."
        }
      }
    }
  }
}

