locals {
  lambda_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Lambda"
  })
}

variable "lambda_function_without_graviton_default_response_option" {
  type        = string
  description = "The default response to use for Lambda functions without graviton."
  default     = "notify"
}

variable "lambda_function_without_graviton_enabled_response_options" {
  type        = list(string)
  description = "The response options given to approvers to determine the chosen response."
  default     = ["skip", "delete_function"]
}