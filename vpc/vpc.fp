locals {
  vpc_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/VPC"
  })
}

variable "vpc_eips_unattached_default_action" {
  type        = string
  description = "The default response to use when elastic IP addresses are unattached."
  default     = "notify"
}

variable "vpc_eips_unattached_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "release"]
}

variable "vpc_nat_gateways_unused_default_action" {
  type        = string
  description = "The default response to use when NAT gateways are unused."
  default     = "notify"
}

variable "vpc_nat_gateways_unused_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete"]
}