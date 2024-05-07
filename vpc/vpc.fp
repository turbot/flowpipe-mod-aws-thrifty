locals {
  vpc_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/VPC"
  })
}

variable "unattached_elastic_ip_addresses_default_action" {
  type        = string
  description = "The default response to use when elastic IP addresses are unattached."
  default     = "notify"
}

variable "unattached_elastic_ip_addresses_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "release"]
}

variable "unused_nat_gateways_default_action" {
  type        = string
  description = "The default response to use when NAT gateways are unused."
  default     = "notify"
}

variable "unused_nat_gateways_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete"]
}