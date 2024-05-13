// Tags
locals {
  aws_thrifty_common_tags = {
    category = "Cost"
    plugin   = "aws"
    service  = "AWS"
  }
}

// Consts
locals {
  level_verbose = "verbose"
  level_info    = "info"
  level_error   = "error"
  style_ok      = "ok"
  style_info    = "info"
  style_alert   = "alert"
}

// Common Texts
locals {
  description_database        = "Database connection string."
  description_approvers       = "List of notifiers to be used for obtaining action/approval decisions."
  description_credential      = "Name of the credential to be used for any authenticated actions."
  description_region          = "AWS Region of the resource(s)."
  description_title           = "Title of the resource, to be used as a display name."
  description_max_concurrency = "The maximum concurrency to use for responding to detection items."
  description_notifier        = "The name of the notifier to use for sending notification messages."
  description_notifier_level  = "The verbosity level of notification messages to send. Valid options are 'verbose', 'info', 'error'."
  description_default_action  = "The default action to use for the detected item, used if no input is provided."
  description_enabled_actions = "The list of enabled actions to provide to approvers for selection."
}

// Pipeline References
locals {
  pipeline_optional_message                 = detect_correct.pipeline.optional_message
  aws_pipeline_delete_ebs_snapshot          = aws.pipeline.delete_ebs_snapshot
  aws_pipeline_modify_ebs_volume            = aws.pipeline.modify_ebs_volume
  aws_pipeline_stop_ec2_instances           = aws.pipeline.stop_ec2_instances
  aws_pipeline_terminate_ec2_instances      = aws.pipeline.terminate_ec2_instances
  aws_pipeline_delete_ebs_volume            = aws.pipeline.delete_ebs_volume
  aws_pipeline_detach_ebs_volume            = aws.pipeline.detach_ebs_volume
  aws_pipeline_release_eip                  = aws.pipeline.release_eip
  aws_pipeline_delete_nat_gateway           = aws.pipeline.delete_nat_gateway
  aws_pipeline_delete_rds_db_instance       = aws.pipeline.delete_rds_db_instance
  aws_pipeline_update_route53_record        = aws.pipeline.update_route53_record
  aws_pipeline_delete_route53_health_check  = aws.pipeline.delete_route53_health_check
  aws_pipeline_delete_secretsmanager_secret = aws.pipeline.delete_secretsmanager_secret
  aws_pipeline_delete_elbv2_load_balancer   = aws.pipeline.delete_elbv2_load_balancer
  aws_pipeline_delete_elb_load_balancer     = aws.pipeline.delete_elb_load_balancer
  aws_pipeline_delete_elasticache_cluster   = aws.pipeline.delete_elasticache_cluster
  aws_pipeline_delete_eks_node_group        = aws.pipeline.delete_eks_node_group
  aws_pipeline_create_ebs_snapshot          = aws.pipeline.create_ebs_snapshot
}