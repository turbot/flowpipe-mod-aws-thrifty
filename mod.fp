mod "aws_thrifty" {
  title = "AWS Thrifty"
  require {
    mod "github.com/turbot/flowpipe-mod-aws" {
      version = "*"
    }
    mod "github.com/turbot/flowpipe-mod-approval" {
      version = "v0.0.1-alpha.3"
    }
  }
}