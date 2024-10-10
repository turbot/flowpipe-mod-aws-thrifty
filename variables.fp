variable "approvers" {
  type        = list(notifier)
  description = "List of notifiers to be used for obtaining action/approval decisions, when empty list will perform the default response associated with the detection."
  default     = [notifier.default]
}

variable "notifier" {
  type        = notifier
  description = "The notifier to use for sending notification messages."
  default     = notifier.default
}

variable "notification_level" {
  type        = string
  description = "The verbosity level of notification messages to send. Valid options are 'verbose', 'info', 'error'."
  default     = "info"
}

variable "database" {
  type        = connection.steampipe
  description = "Steampipe database connection string."
  default     = connection.steampipe.default

  tags = {
    folder = "Advanced"
  }
}

variable "max_concurrency" {
  type        = number
  description = "The maximum concurrency to use for responding to detection items."
  default     = 1

  tags = {
    folder = "Advanced"
  }
}
