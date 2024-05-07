
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
    filter_clusters;
  where
    date_part('day', now() - cache_cluster_create_time) > ${var.ebs_snapshot_age_max_days};
  EOQ
}

trigger "query" "detect_and_respond_to_elasticache_clusters_exceeding_max_age" {
  title       = "Detect and respond to Elasticache clusters exceeding max age"
  description = "Detects Elasticache clusters exceeding max age and responds with your chosen action."

  enabled  = false
  schedule = var.default_query_trigger_schedule
  database = var.database
  sql      = local.elasticache_clusters_exceeding_max_age_query

  capture "insert" {
    pipeline = pipeline.respond_to_elasticache_clusters_exceeding_max_age
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_elasticache_clusters_exceeding_max_age" {
  title         = "Detect and respond to Elasticache clusters exceeding max age"
  description   = "Detects Elasticache clusters exceeding max age and responds with your chosen action."
  // tags          = merge(local.elasticache_common_tags, { class = "unused" })

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
    default     = var.elasticache_cluster_age_max_days_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.elasticache_cluster_age_max_days_enabled_response_options
  }

  step "query" "detect" {
    database = param.database
    sql      = local.elasticache_clusters_exceeding_max_age_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_elasticache_clusters_exceeding_max_age
    args     = {
      items                    = step.query.detect.rows
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
    }
  }
}

pipeline "respond_to_elasticache_clusters_exceeding_max_age" {
  title         = "Respond to Elasticache clusters exceeding max age"
  description   = "Responds to a collection of Elasticache clusters exceeding max age."
  // tags          = merge(local.elasticache_common_tags, { class = "unused" })

  param "items" {
    type = list(object({
      title       = string
      name        = string
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
    default     = var.elasticache_cluster_age_max_days_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.elasticache_cluster_age_max_days_enabled_response_options
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} Elasticache Clusters exceeding maximum age."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.name => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_elasticache_cluster_exceeding_max_age
    args            = {
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

pipeline "respond_to_elasticache_cluster_exceeding_max_age" {
  title         = "Respond to Elasticache cluster exceeding max age"
  description   = "Responds to an Elasticache cluster exceeding max age."
  // tags          = merge(local.elasticache_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "name" {
    type        = string
    description = "The ID of the Elasticache cluster."
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
    default     = var.elasticache_cluster_age_max_days_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.elasticache_cluster_age_max_days_enabled_response_options
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args     = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected Elasticache Cluster ${param.title} exceeding maximum age."
      default_response_option  = param.default_response_option
      enabled_response_options = param.enabled_response_options
      response_options = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.StyleInfo
          pipeline_ref  = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped Elasticache Cluster ${param.title} exceeding maximum age."
          }
          success_msg = ""
          error_msg   = ""
        },
        "delete_cluster" = {
          label  = "Delete Cluster"
          value  = "delete_cluster"
          style  = local.StyleAlert
          pipeline_ref  = local.mock_aws_pipeline_delete_elasticache_cluster
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

// TODO: We can remove this mock pipeline once the real pipeline is added to the aws library mod.
pipeline "mock_aws_pipeline_delete_elasticache_cluster" {
  param "name" {
    type = string
  }

  param "region" {
    type = string
  }

  param "cred" {
    type = string
  }

  output "result" {
    value = "Mocked: Delete Elasticache Cluster [Cache_Cluster_ID: ${param.name}, Region: ${param.region}, Cred: ${param.cred}]"
  }
}