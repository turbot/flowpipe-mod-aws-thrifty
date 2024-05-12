locals {
  emr_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/EMR"
  })
}

// variable "emr_clusters_previous_generation_default_action" {
//   type        = string
//   description = "The default response to use for EMR clusters of previous generation instances."
//   default     = "notify"
// }

// variable "emr_clusters_previous_generation_enabled_response_options" {
//   type        = list(string)
//   description = "The response options given to approvers to determine the chosen response."
//   default     = ["skip", "delete_function"]
// }

// variable "emr_clusters_previous_generation" {
//   type        = list(string)
//   description = "A list of previous generation EMR cluster instance types."
//   default     = ["c1.%", "cc2.%", "cr1.%", "m2.%", "g2.%", "i2.%", "m1.%"]
// }
