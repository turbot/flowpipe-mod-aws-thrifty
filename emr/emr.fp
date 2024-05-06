locals {
  emr_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EMR"
  })
}

variable "emr_cluster_previous_generation_default_response_option" {
  type        = string
  description = "The default response to use for EMR clusters of previous generation instances."
  default     = "notify"
}

variable "emr_cluster_previous_generation_enabled_response_options" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_function"]
}

variable "emr_cluster_previous_generation" {
  type        = list(string)
  description = "A list of previous generation EMR cluster instance types."
  default     = ["c1.%", "cc2.%", "cr1.%", "m2.%", "g2.%", "i2.%", "m1.%"]
}

variable "emr_cluster_idle_30_mins_default_response_option" {
  type        = string
  description = "The default response to use for EMR clusters of previous generation instances."
  default     = "notify"
}

variable "emr_cluster_idle_30_mins_enabled_response_options" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "stop_cluster", "delete_cluster"]
}