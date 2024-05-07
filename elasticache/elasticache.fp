locals {
  elasticache_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/ElastiCache"
  })
}

variable "elasticache_cluster_age_max_days" {
  type        = number
  description = "The maximum number of days Elasticache clusters can be retained."
  default     = 90
}

variable "elasticache_cluster_age_max_days_default_action" {
  type        = string
  description = "The default response to use when EBS snapshots are older than the maximum number of days."
  default     = "notify"
}

variable "elasticache_cluster_age_max_days_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_cluster"]
}