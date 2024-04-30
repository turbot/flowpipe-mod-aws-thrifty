locals {
  ec2_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EC2"
  })
}

variable "ec2_instance_age_max_days" {
  type        = number
  description = "The maximum number of days EBS snapshots can be retained."
  default     = 3
}

variable "ec2_instance_age_max_days_default_response" {
  type        = string
  description = "The default response to use when EBS snapshots are older than the maximum number of days."
  default     = "notify"
}

variable "ec2_instance_age_max_days_responses" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "stop", "terminate"]
}