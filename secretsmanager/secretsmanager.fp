locals {
  secretsmanager_common_tags = merge(local.aws_thrifty_common_tags, {
    service = "AWS/Secrets Manager"
  })
}
