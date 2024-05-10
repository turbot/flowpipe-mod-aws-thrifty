mod "aws_thrifty" {
  title         = "AWS Thrifty"
  description   = "Run pipelines to remediate AWS resources that are unused and underutilized."
  color         = "#FF9900"
  documentation = file("./README.md")
  icon          = "/images/mods/turbot/aws.svg"
  categories    = ["public cloud"]
  require {
    mod "github.com/turbot/flowpipe-mod-aws" {
      version = "v0.1.1-rc.5"
    }
    mod "github.com/turbot/flowpipe-mod-detect-correct" {
      version = "v0.0.1-alpha.1"
    }
  }
}