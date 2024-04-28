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
  approval_pipeline_skipped_action_notification = approval.pipeline.skipped_action_notification
  aws_pipeline_delete_ebs_snapshot = aws.pipeline.delete_ebs_snapshot
}