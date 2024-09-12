variable "database" {
  type        = string
  description = "Steampipe database connection string."
  default     = "postgres://steampipe@localhost:9193/steampipe"

  tags        = {
    folder = "Advanced/Global"
  }
}

variable "max_concurrency" {
  type        = number
  description = "The maximum concurrency to use for responding to detection items."
  default     = 1

  tags        = {
    folder = "Advanced/Global"
  }
}

variable "notifier" {
  type        = string
  description = "The name of the notifier to use for sending notification messages."
  default     = "default"
}

variable "notification_level" {
  type        = string
  description = "The verbosity level of notification messages to send. Valid options are 'verbose', 'info', 'error'."
  default     = "info"
}

variable "approvers" {
  type        = list(string)
  description = "List of notifiers to be used for obtaining action/approval decisions, when empty list will perform the default response associated with the detection."
  default     = ["default"]
}
