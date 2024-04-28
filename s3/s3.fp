locals {
  s3_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/S3"
  })
}

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

variable "s3_bucket_without_lifecycle_policy_default_response" {
  type        = string
  description = "The default response to use for S3 buckets without lifecycle policy."
  default     = "notify"
}

variable "s3_bucket_without_lifecycle_policy_responses" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "apply"]
}