locals {
  eks_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EKS"
  })
}

variable "eks_node_group_without_graviton_enabled_response_options" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_node_group"]
}

variable "eks_node_group_without_graviton_default_response_option" {
  type        = string
  description = "The default response to use for EKS node groups without graviton."
  default     = "notify"
}