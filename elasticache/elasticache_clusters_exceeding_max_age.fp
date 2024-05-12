
locals {
  elasticache_clusters_exceeding_max_age_query = <<-EOQ
    with filter_clusters as (
    select
      distinct c.replication_group_id as name,
      c.cache_cluster_create_time,
      c._ctx,
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
      _ctx,
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
    _ctx ->> 'connection_name' as cred
  from
    filter_clusters
  where
    date_part('day', now() - cache_cluster_create_time) > ${var.elasticache_clusters_exceeding_max_age_days};
  EOQ
}

trigger "query" "detect_and_correct_elasticache_clusters_exceeding_max_age" {
  title         = "Detect & correct Elasticache clusters exceeding max age"
  description   = "Detects Elasticache clusters exceeding max age and responds with your chosen action."
  documentation = file("./elasticache/docs/detect_and_correct_elasticache_clusters_exceeding_max_age_trigger.md")
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
  documentation = file("./elasticache/docs/detect_and_correct_elasticache_clusters_exceeding_max_age.md")
  tags          = merge(local.elasticache_common_tags, { class = "managed", type = "featured" })

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

  param "default_response_option" {
    type        = string
    description = local.description_default_action
    default     = var.elasticache_clusters_exceeding_max_age_default_action
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.elasticache_clusters_exceeding_max_age_enabled_actions
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
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
    }
  }
}

pipeline "correct_elasticache_clusters_exceeding_max_age" {
  title         = "Correct Elasticache clusters exceeding max age"
  description   = "Runs corrective action on a collection of Elasticache clusters exceeding max age."
  documentation = file("./elasticache/docs/correct_elasticache_clusters_exceeding_max_age.md")
  tags          = merge(local.elasticache_common_tags, { class = "managed" })

  param "items" {
    type = list(object({
      title  = string
      name   = string
      region = string
      cred   = string
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

  param "default_response_option" {
    type        = string
    description = local.description_default_action
    default     = var.elasticache_clusters_exceeding_max_age_default_action
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.elasticache_clusters_exceeding_max_age_enabled_actions
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = notifier[param.notifier]
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
      cred                     = each.value.cred
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
    }
  }
}

pipeline "correct_one_elasticache_cluster_exceeding_max_age" {
  title         = "Correct one Elasticache cluster exceeding max age"
  description   = "Runs corrective action on an Elasticache cluster exceeding max age."
  documentation = file("./elasticache/docs/correct_one_elasticache_cluster_exceeding_max_age.md")
  tags          = merge(local.elasticache_common_tags, { class = "managed" })

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

  param "default_response_option" {
    type        = string
    description = local.description_default_action
    default     = var.elasticache_clusters_exceeding_max_age_default_action
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.elasticache_clusters_exceeding_max_age_enabled_actions
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected Elasticache Cluster ${param.title} exceeding maximum age."
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
      response_options = {
        "skip" = {
          label        = "Skip"
          value        = "skip"
          style        = local.style_info
          pipeline_ref = local.pipeline_optional_message
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
          pipeline_ref = local.aws_pipeline_delete_elasticache_cluster
          pipeline_args = {
            cache_cluster_id = param.name
            region           = param.region
            cred             = param.cred
          }
          success_msg = "Deleted Elasticache Cluster ${param.title}."
          error_msg   = "Error deleting Elasticache Cluster ${param.title}."
        }
      }
    }
  }
}

variable "elasticache_clusters_exceeding_max_age_trigger_enabled" {
  type    = bool
  default = false
}

variable "elasticache_clusters_exceeding_max_age_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "elasticache_clusters_exceeding_max_age_days" {
  type        = number
  description = "The maximum number of days Elasticache clusters can be retained."
  default     = 90
}

variable "elasticache_clusters_exceeding_max_age_default_action" {
  type        = string
  description = "The default response to use when EBS snapshots are older than the maximum number of days."
  default     = "notify"
}

variable "elasticache_clusters_exceeding_max_age_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_cluster"]
}