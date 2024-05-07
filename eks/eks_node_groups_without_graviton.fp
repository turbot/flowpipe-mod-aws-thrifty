locals {
  eks_node_groups_without_graviton_query = <<-EOQ
    with node_group_using_launch_template_image_id as (
      select
        g.arn as node_group_arn,
        v.image_id as image_id
      from
        aws_eks_node_group as g
        left join aws_ec2_launch_template_version as v on v.launch_template_id = g.launch_template ->> 'Id' and v.version_number = (g.launch_template ->> 'Version')::int
      where
        g.launch_template is not null
    ), ami_architecture as (
      select
        node_group_arn,
        architecture,
        case when s.platform_details = 'Linux/UNIX' then 'linux' else platform_details end as platform
      from
        node_group_using_launch_template_image_id as i
        left join aws_ec2_ami_shared as s on s.image_id = i.image_id
      where
        architecture is not null
      union
      select
        node_group_arn,
        architecture,
        case when a.platform_details = 'Linux/UNIX' then 'linux' else platform_details end as platform
      from
        node_group_using_launch_template_image_id as i
        left join aws_ec2_ami as a on a.image_id = i.image_id
      where
        architecture is not null
  )
  select
    concat(g.nodegroup_name, ' [', g.region, '/', g.account_id, ']') as title,
    g.cluster_name,
    g.nodegroup_name,
    g.region,
    g._ctx ->> 'connection_name' as cred
  from
    aws_eks_node_group as g
    left join ami_architecture as a on a.node_group_arn = g.arn
  where
    ami_type = 'CUSTOM%' and a.architecture <> 'arm_64' and a.platform = 'linux';
  EOQ
}

trigger "query" "detect_and_respond_to_eks_node_groups_without_graviton" {
  title       = "Detect and respond to EKS node groups without graviton processor"
  description = "Detects EKS node groups without graviton processor and responds with your chosen action."

  enabled  = var.eks_node_groups_without_graviton_trigger_enabled
  schedule = var.eks_node_groups_without_graviton_trigger_schedule
  database = var.database
  sql      = local.eks_node_groups_without_graviton_query

  capture "insert" {
    pipeline = pipeline.respond_to_eks_node_groups_without_graviton
    args     = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_respond_to_eks_node_groups_without_graviton" {
  title         = "Detect and respond to EKS node groups without graviton processor"
  description   = "Detects EKS node groups without graviton processor and responds with your chosen action."
  // tags          = merge(local.eks_common_tags, {
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
    default     = var.eks_node_group_without_graviton_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.eks_node_group_without_graviton_enabled_response_options
  }

  step "query" "detect" {
    database = param.database
    sql      = local.eks_node_groups_without_graviton_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.respond_to_eks_node_groups_without_graviton
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

pipeline "respond_to_eks_node_groups_without_graviton" {
  title         = "Respond to EKS node groups without graviton processor"
  description   = "Responds to a collection of EKS node groups without graviton processor."
  // tags          = merge(local.eks_common_tags, { 
  //   class = "deprecated" 
  // })

  param "items" {
    type = list(object({
      title           = string
      cluster_name    = string
      nodegroup_name  = string
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

  param "default_response_option" {
    type        = string
    description = local.DefaultResponseDescription
    default     = var.eks_node_group_without_graviton_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.eks_node_group_without_graviton_enabled_response_options
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.NotifierLevelVerbose
    notifier = notifier[param.notifier]
    text     = "Detected ${length(param.items)} EKS node groups without graviton processor."
  }

  step "transform" "items_by_id" {
    value = {for row in param.items : row.instance_id => row }
  }

  step "pipeline" "respond_to_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.respond_to_eks_node_group_without_graviton
    args            = {
      title                      = each.value.title
      cluster_name               = each.value.cluster_name
      nodegroup_name             = each.value.nodegroup_name
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

pipeline "respond_to_eks_node_group_without_graviton" {
  title         = "Respond to an EKS node group without graviton processor"
  description   = "Responds to an EKS node group without graviton processor."
  // tags          = merge(local.eks_common_tags, { class = "unused" })

  param "title" {
    type        = string
    description = local.TitleDescription
  }

  param "cluster_name" {
    type        = string
    description = "The name of the EKS node group cluster."
  }

  param "nodegroup_name" {
    type        = string
    description = "The name of the EKS node group."
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
    default     = var.eks_node_group_without_graviton_default_response_option
  }

  param "enabled_response_options" {
    type        = list(string)
    description = local.ResponsesDescription
    default     = var.eks_node_group_without_graviton_enabled_response_options
  }

  step "pipeline" "respond" {
    pipeline = approval.pipeline.respond_action_handler
    args     = {
      notifier         = param.notifier
      notification_level   = param.notification_level
      approvers        = param.approvers
      detect_msg       = "Detected EKS Node Group ${param.title} without graviton processor."
      default_response_option           = param.default_response_option
      enabled_response_options        = param.enabled_response_options
      response_options = {
        "skip" = {
          label  = "Skip"
          value  = "skip"
          style  = local.StyleInfo
          pipeline_ref  = local.approval_pipeline_skipped_action_notification
          pipeline_args = {
            notifier = param.notifier
            send     = param.notification_level == local.NotifierLevelVerbose
            text     = "Skipped EKS Node Group ${param.title} without graviton processor."
          }
          success_msg = "Skipped EKS Node Group ${param.title}."
          error_msg   = "Error skipping EKS Node Group ${param.title}."
        },
        "delete_node_group" = {
          label  = "Terminate Instance"
          value  = "delete_node_group"
          style  = local.StyleAlert
          pipeline_ref  = local.aws_pipeline_delete_eks_node_group
          pipeline_args = {
            cluster_name    = param.cluster_name
            nodegroup_name  = param.nodegroup_name
            region          = param.region
            cred            = param.cred
          }
          success_msg = "Deleted EKS Node Group ${param.title}."
          error_msg   = "Error deleting EKS Node Group ${param.title}."
        }
      }
    }
  }
}

pipeline "mock_aws_pipeline_delete_eks_node_group" {
  param "cluster_name" {
    type = string
  }

  param "nodegroup_name" {
    type = string
  }

  param "region" {
    type = string
  }

  param "cred" {
    type = string
  }

  output "result" {
    value = "Mocked: Delete EKS Cluster Node Group [Name: ${param.nodegroup_name}, Region: ${param.region}, Cred: ${param.cred}]"
  }
}