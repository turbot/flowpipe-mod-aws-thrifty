locals {
  ebs_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EBS"
  })
}

variable "ebs_volume_max_size_gb" {
  type        = number
  description = "The maximum size (GB) allowed for volumes."
  default     = 100
}

variable "ebs_volume_avg_read_write_ops_low" {
  type        = number
  description = "The number of average read/write ops required for volumes to be considered infrequently used."
  default     = 100
}

variable "ebs_volume_max_iops" {
  type        = number
  description = "The maximum IOPS allowed for volumes."
  default     = 32000
}

variable "ebs_snapshot_age_max_days_default_action" {
  type        = string
  description = "The default response to use when EBS snapshots are older than the maximum number of days."
  default     = "notify"
}

variable "ebs_snapshot_age_max_days_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_snapshot"]
}

variable "ebs_volume_using_gp2_default_action" {
  type        = string
  description = "The default response to use when EBS volumes are using gp2."
  default     = "notify"
}

variable "ebs_volume_using_gp2_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "update_to_gp3"]
}

variable "ebs_volume_using_io1_default_action" {
  type        = string
  description = "The default response to use when EBS volumes are using io1."
  default     = "notify"
}

variable "ebs_volume_using_io1_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "update_to_io2"]
}

variable "ebs_volume_without_attachments_default_action" {
  type        = string
  description = "The default response to use when EBS volumes are unattached."
  default     = "notify"
}

variable "ebs_volume_without_attachments_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_volume"]
}

variable "ebs_volume_unattached_default_action" {
  type        = string
  description = "The default response to use when EBS volumes are unattached."
  default     = "notify"
}

variable "ebs_volume_unattached_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_volume"]
}


variable "ebs_volume_large_default_action" {
  type        = string
  description = "The default response to use when EBS volumes are larger than the specified size."
  default     = "notify"
}

variable "ebs_volume_large_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_volume"]
}

variable "ebs_volume_with_low_usage_default_action" {
  type        = string
  description = "The default response to use when EBS volumes read/write ops are less than the specified average read/write ops."
  default     = "notify"
}

variable "ebs_volume_with_low_usage_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_volume"]
}

variable "ebs_volume_with_low_iops_default_action" {
  type        = string
  description = "The default response to use when EBS volumes with low iops."
  default     = "notify"
}

variable "ebs_volume_with_low_iops_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_volume"]
}

variable "ebs_volume_with_high_iops_default_action" {
  type        = string
  description = "The default response to use when EBS volumes with high iops."
  default     = "notify"
}

variable "ebs_volume_with_high_iops_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_volume"]
}
