locals {
  ebs_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EBS"
  })
}

variable "ebs_snapshot_age_max_days" {
  type        = number
  description = "The maximum number of days EBS snapshots can be retained."
  default     = 90
}

variable "ebs_snapshot_age_max_days_default_response" {
  type        = string
  description = "The default response to use when EBS snapshots are older than the maximum number of days."
  default     = "notify"
}

variable "ebs_snapshot_age_max_days_responses" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete"]
}

variable "ebs_volume_using_gp2_default_response" {
  type        = string
  description = "The default response to use when EBS volumes are using gp2."
  default     = "notify"
}

variable "ebs_volume_using_gp2_responses" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "update"]
}

variable "ebs_volume_using_io1_default_response" {
  type        = string
  description = "The default response to use when EBS volumes are using io1."
  default     = "notify"
}

variable "ebs_volume_using_io1_responses" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "update"]
}

variable "ebs_volume_without_attachments_default_response" {
  type        = string
  description = "The default response to use when EBS volumes are unattached."
  default     = "notify"
}

variable "ebs_volume_without_attachments_responses" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete"]
}