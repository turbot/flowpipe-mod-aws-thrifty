locals {
  ecs_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/ECS"
  })
}

variable "ecs_cluster_container_instance_without_graviton_default_action" {
  type        = string
  description = "The default response to use when there are older generation EC2 instances."
  default     = "notify"
}

variable "ecs_cluster_container_instance_without_graviton_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "stop_instance", "terminate_instance"]
}