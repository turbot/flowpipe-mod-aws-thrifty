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
  NotifierLevelVerbose = "verbose"
  NotifierLevelInfo    = "info"
  NotifierLevelError   = "error"
  StyleOk              = "ok"
  StyleInfo            = "info"
  StyleAlert           = "alert"
}

// Common Texts
// TODO: Change to snake_case for consistency
locals {
  DatabaseDescription        = "Database connection string."
  ApproversDescription       = "List of notifiers to be used for obtaining action/approval decisions."
  CredentialDescription      = "Name of the credential to be used for any authenticated actions."
  RegionDescription          = "AWS Region of the resource(s)."
  TitleDescription           = "Title of the resource, to be used as a display name."
  MaxConcurrencyDescription  = "The maximum concurrency to use for responding to detection items."
  NotifierDescription        = "The name of the notifier to use for sending notification messages."
  NotifierLevelDescription   = "The verbosity level of notification messages to send. Valid options are 'verbose', 'info', 'error'."
  DefaultResponseDescription = "The default response to use for the detected item, used if no input is provided."
  ResponsesDescription       = "The list of responses to provide to approvers for selection."
}

// Pipeline References
locals {
  aws_pipeline_delete_lambda_functions = aws.pipeline.delete_lambda_function
  pipeline_optional_message            = detect_correct.pipeline.optional_message
  aws_pipeline_delete_ebs_snapshot     = aws.pipeline.delete_ebs_snapshot
  aws_pipeline_modify_ebs_volume       = aws.pipeline.modify_ebs_volume
  aws_pipeline_stop_ec2_instances      = aws.pipeline.stop_ec2_instances
  aws_pipeline_terminate_ec2_instances = aws.pipeline.terminate_ec2_instances
  aws_pipeline_delete_ebs_volume       = pipeline.mock_aws_pipeline_delete_ebs_volume  // aws.pipeline.delete_ebs_volume
  aws_pipeline_detach_ebs_volume       = pipeline.mock_aws_pipeline_detach_ebs_volume  // aws.pipeline.detach_ebs_volume
  aws_pipeline_release_eip             = pipeline.mock_aws_pipeline_release_eip        // aws.pipeline.release_eip
  aws_pipeline_delete_nat_gateway      = pipeline.mock_aws_pipeline_delete_nat_gateway // aws.pipeline.delete_nat_gateway
  aws_pipeline_delete_rds_db_instance  = pipeline.mock_aws_pipeline_delete_rds_instance // aws.pipeline.delete_rds_db_instance
}