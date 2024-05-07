locals {
  s3_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/S3"
  })
}

variable "s3_buckets_without_lifecycle_policy_trigger_enabled" {
  type    = bool
  default = false
}

variable "s3_buckets_without_lifecycle_policy_trigger_schedule" {
  type    = string
  default = "15m"
}

// TODO: Change to an array of objects (contents of 'Rules') - let lib mod wrap it; no JSONified strings!
// TODO: Change to s3_buckets_without_lifecycle_policy_default_policy
// TODO: Iterate all other variables that're specific and ensure they're prefixed with full prefix & pluralised
// TODO: Safer default (no deletion) - check other variables!
variable "s3_bucket_default_lifecycle_policy" {
  type        = string
  description = "The default S3 bucket lifecycle policy to apply"
  default     = <<-EOF
{
  "Rules": [
    {
      "ID": "Expire all objects after one year",
      "Status": "Enabled",
      "Expiration": {
        "Days": 365
      }
    }
  ]
}
  EOF
}

// TODO: Pluralise across all
variable "s3_bucket_without_lifecycle_policy_default_action" {
  type        = string
  description = "The default response to use for S3 buckets without lifecycle policy."
  default     = "notify"
}

// TODO: Pluralise across all
variable "s3_bucket_without_lifecycle_policy_enabled_actions" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "apply_policy"]
}