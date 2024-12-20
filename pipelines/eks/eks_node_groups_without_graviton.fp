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
    g.sp_connection_name as conn
  from
    aws_eks_node_group as g
    left join ami_architecture as a on a.node_group_arn = g.arn
  where
    ami_type = 'CUSTOM%' and a.architecture <> 'arm_64' and a.platform = 'linux';
  EOQ

  eks_node_groups_without_graviton_default_action_enum  = ["notify", "skip", "delete_node_group"]
  eks_node_groups_without_graviton_enabled_actions_enum = ["skip", "delete_node_group"]
}

variable "eks_node_groups_without_graviton_trigger_enabled" {
  type        = bool
  default     = false
  description = "If true, the trigger is enabled."
  tags = {
    folder = "Advanced/EKS"
  }
}

variable "eks_node_groups_without_graviton_trigger_schedule" {
  type        = string
  default     = "15m"
  description = "The schedule on which to run the trigger if enabled."
  tags = {
    folder = "Advanced/EKS"
  }
}

variable "eks_node_groups_without_graviton_default_action" {
  type        = string
  description = "The default action to use for the detected item, used if no input is provided."
  default     = "notify"
  enum        = ["notify", "skip", "delete_node_group"]
  tags = {
    folder = "Advanced/EKS"
  }
}

variable "eks_node_groups_without_graviton_enabled_actions" {
  type        = list(string)
  description = "The list of enabled actions to provide to approvers for selection."
  default     = ["skip", "delete_node_group"]
  enum        = ["skip", "delete_node_group"]
  tags = {
    folder = "Advanced/EKS"
  }
}

trigger "query" "detect_and_correct_eks_node_groups_without_graviton" {
  title         = "Detect & correct EKS node groups without graviton"
  description   = "Detects EKS node groups without graviton processor and responds with your chosen action."
  documentation = file("./pipelines/eks/docs/detect_and_correct_eks_node_groups_without_graviton_trigger.md")
  tags          = merge(local.eks_common_tags, { class = "deprecated" })

  enabled  = var.eks_node_groups_without_graviton_trigger_enabled
  schedule = var.eks_node_groups_without_graviton_trigger_schedule
  database = var.database
  sql      = local.eks_node_groups_without_graviton_query

  capture "insert" {
    pipeline = pipeline.correct_eks_node_groups_without_graviton
    args = {
      items = self.inserted_rows
    }
  }
}

pipeline "detect_and_correct_eks_node_groups_without_graviton" {
  title         = "Detect & correct EKS node groups without graviton"
  description   = "Detects EKS node groups without graviton processor and responds with your chosen action."
  documentation = file("./pipelines/eks/docs/detect_and_correct_eks_node_groups_without_graviton.md")
  tags          = merge(local.eks_common_tags, { class = "deprecated", recommended = "true" })

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
    default     = var.eks_node_groups_without_graviton_default_action
    enum        = local.eks_node_groups_without_graviton_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.eks_node_groups_without_graviton_enabled_actions
    enum        = local.eks_node_groups_without_graviton_enabled_actions_enum
  }

  step "query" "detect" {
    database = param.database
    sql      = local.eks_node_groups_without_graviton_query
  }

  step "pipeline" "respond" {
    pipeline = pipeline.correct_eks_node_groups_without_graviton
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

pipeline "correct_eks_node_groups_without_graviton" {
  title         = "Correct EKS node groups without graviton"
  description   = "Runs corrective action on a collection of EKS node groups without graviton processor."
  documentation = file("./pipelines/eks/docs/correct_eks_node_groups_without_graviton.md")
  tags          = merge(local.eks_common_tags, { class = "deprecated", folder = "Internal" })

  param "items" {
    type = list(object({
      title          = string
      cluster_name   = string
      nodegroup_name = string
      region         = string
      conn           = string
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
    default     = var.eks_node_groups_without_graviton_default_action
    enum        = local.eks_node_groups_without_graviton_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.eks_node_groups_without_graviton_enabled_actions
    enum        = local.eks_node_groups_without_graviton_enabled_actions_enum
  }

  step "message" "notify_detection_count" {
    if       = var.notification_level == local.level_verbose
    notifier = param.notifier
    text     = "Detected ${length(param.items)} EKS node groups without graviton processor."
  }

  step "transform" "items_by_id" {
    value = { for row in param.items : row.instance_id => row }
  }

  step "pipeline" "correct_item" {
    for_each        = step.transform.items_by_id.value
    max_concurrency = var.max_concurrency
    pipeline        = pipeline.correct_one_eks_node_group_without_graviton
    args = {
      title                    = each.value.title
      cluster_name             = each.value.cluster_name
      nodegroup_name           = each.value.nodegroup_name
      region                   = each.value.region
      conn                     = connection.aws[each.value.conn]
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      default_action           = param.default_action
      enabled_actions          = param.enabled_actions
    }
  }
}

pipeline "correct_one_eks_node_group_without_graviton" {
  title         = "Correct one EKS node group without graviton"
  description   = "Runs corrective action on an EKS node group without graviton processor."
  documentation = file("./pipelines/eks/docs/correct_one_eks_node_group_without_graviton.md")
  tags          = merge(local.eks_common_tags, { class = "deprecated", folder = "Internal" })

  param "title" {
    type        = string
    description = local.description_title
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
    default     = var.eks_node_groups_without_graviton_default_action
    enum        = local.eks_node_groups_without_graviton_default_action_enum
  }

  param "enabled_actions" {
    type        = list(string)
    description = local.description_enabled_actions
    default     = var.eks_node_groups_without_graviton_enabled_actions
    enum        = local.eks_node_groups_without_graviton_enabled_actions_enum
  }

  step "pipeline" "respond" {
    pipeline = detect_correct.pipeline.correction_handler
    args = {
      notifier                 = param.notifier
      notification_level       = param.notification_level
      approvers                = param.approvers
      detect_msg               = "Detected EKS Node Group ${param.title} without graviton processor."
      default_response_option  = param.default_response_option
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
            text     = "Skipped EKS Node Group ${param.title} without graviton processor."
          }
          success_msg = "Skipped EKS Node Group ${param.title}."
          error_msg   = "Error skipping EKS Node Group ${param.title}."
        },
        "delete_node_group" = {
          label        = "Delete Node Group"
          value        = "delete_node_group"
          style        = local.style_alert
          pipeline_ref = aws.pipeline.delete_eks_node_group
          pipeline_args = {
            cluster_name   = param.cluster_name
            nodegroup_name = param.nodegroup_name
            region         = param.region
            conn           = param.conn
          }
          success_msg = "Deleted EKS Node Group ${param.title}."
          error_msg   = "Error deleting EKS Node Group ${param.title}."
        }
      }
    }
  }
}


