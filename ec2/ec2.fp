locals {
  ec2_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EC2"
  })
}

variable "ec2_instance_age_max_days" {
  type        = number
  description = "The maximum number of days EC2 instances can be retained."
  default     = 90 
}

variable "ec2_instance_age_max_days_default_action" {
  type        = string
  description = "The default response to use when EC2 instances are older than the maximum number of days."
  default     = "notify"
}

variable "ec2_instance_age_max_days_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "stop_instance", "terminate_instance"]
}

variable "ec2_application_load_balancer_unused_default_action" {
  type        = string
  description = "The default response to use for unused EC2 application load balancers."
  default     = "notify"
}

variable "ec2_application_load_balancer_unused_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_application_load_balancer"]
}

variable "ec2_classic_load_balancer_unused_default_action" {
  type        = string
  description = "The default response to use for unused EC2 classic load balancers."
  default     = "notify"
}

variable "ec2_classic_load_balancer_unused_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_classic_load_balancer"]
}

variable "ec2_gateway_load_balancer_unused_default_action" {
  type        = string
  description = "The default response to use for unused EC2 classic load balancers."
  default     = "notify"
}

variable "ec2_gateway_load_balancer_unused_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_gateway_load_balancer"]
}

variable "ec2_network_load_balancer_unused_default_action" {
  type        = string
  description = "The default response to use for unused EC2 classic load balancers."
  default     = "notify"
}

variable "ec2_network_load_balancer_unused_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_network_load_balancer"]
}

variable "ec2_instance_allowed_types" {
  type        = list(string)
  description = "A list of allowed instance types. PostgreSQL wildcards are supported."
  default     = ["%.nano", "%.micro", "%.small", "%.medium", "%.large", "%.xlarge", "%._xlarge"]
}

variable "ec2_instance_large_default_action" {
  type        = string
  description = "The default response to use when EC2 instances are larger than the specified types."
  default     = "notify"
}

variable "ec2_instance_large_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "stop_instance", "terminate_instance"]
}

variable "ec2_instance_older_generation_default_action" {
  type        = string
  description = "The default response to use when there are older generation EC2 instances."
  default     = "notify"
}

variable "ec2_instance_older_generation_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "stop_instance", "terminate_instance"]
}

variable "ec2_instance_without_graviton_default_action" {
  type        = string
  description = "The default response to use when there are EC2 instances that do not use graviton processor."
  default     = "notify"
}

variable "ec2_instance_without_graviton_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "stop_instance", "terminate_instance"]
}