variable "database" {
  type        = string
  description = "Steampipe database connection string."
  default     = "postgres://steampipe@localhost:9193/steampipe"
}

variable "default_query_trigger_schedule" {
  type        = string
  description = "Default schedule for query triggers."
  default     = "15m"
}

variable "notifier" {
  type        = string
  description = "The name of the notifier to use for sending notification messages."
  default     = "default"
}

variable "notifier_level" {
  type        = string
  description = "The verbosity level of notification messages to send. Valid options are 'verbose', 'info', 'error'."
  default     = "info"
}

variable "approvers" {
  type        = list(string)
  description = "List of notifiers to be used for obtaining action/approval decisions."
  default     = []
}

variable "max_concurrency" {
  type        = number
  description = "The maximum concurrency to use for responding to detection items."
  default     = 1
}