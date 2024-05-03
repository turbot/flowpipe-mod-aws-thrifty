locals {
  s3_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/S3"
  })
}

// TODO: Change to an array of objects (contents of 'Rules') - let lib mod wrap it; no JSONified strings!
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

variable "s3_bucket_without_lifecycle_policy_default_response_option" {
  type        = string
  description = "The default response to use for S3 buckets without lifecycle policy."
  default     = "notify"
}

variable "s3_bucket_without_lifecycle_policy_enabled_response_options" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "apply_policy"]
}