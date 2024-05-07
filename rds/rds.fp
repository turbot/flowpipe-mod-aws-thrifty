locals {
  rds_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/RDS"
  })
}

variable "rds_running_db_instance_age_max_days" {
  type        = number
  description = "The maximum number of days DB instances are allowed to run."
  default     = 90
}

variable "rds_db_instance_long_running_default_action" {
  type        = string
  description = "The default response to use when RDS DB instances are long running."
  default     = "notify"
}

variable "rds_db_instance_long_running_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_instance"]
}

variable "rds_db_instance_without_graviton_default_action" {
  type        = string
  description = "The default response to use when there are RDS DB instances without graviton processor."
  default     = "notify"
}

variable "rds_db_instance_without_graviton_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_instance"]
}

variable "rds_db_instance_older_generation_default_action" {
  type        = string
  description = "The default response to use when there are older generation RDS DB instances."
  default     = "notify"
}

variable "rds_db_instance_older_generation_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_instance"]
}

variable "rds_db_instance_low_connection_count_default_action" {
  type        = string
  description = "The default response to use when there are RDS DB instances with low connection count."
  default     = "notify"
}

variable "rds_db_instance_low_connection_count_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_instance"]
}