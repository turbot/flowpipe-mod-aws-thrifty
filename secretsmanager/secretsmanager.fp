locals {
  secretsmanager_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Secrets Manager"
  })
}

variable "secretsmanager_secret_unused_days" {
  type        = number
  description = "The default number of days secrets manager secrets to be considered in-use."
  default     = 90
}

variable "secretsmanager_secret_unused_default_action" {
  type        = string
  description = "The default response to use when secrets manager secrets are unused."
  default     = "notify"
}

variable "secretsmanager_secret_unused_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_secret"]
}