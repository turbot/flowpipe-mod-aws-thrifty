mod "aws_thrifty" {
  title         = "AWS Thrifty"
  description   = "Run pipelines to remediate AWS resources that are unused and underutilized."
  color         = "#FF9900"
  documentation = file("./README.md")
  icon          = "/images/mods/turbot/aws.svg"
  categories    = ["public cloud"]

  opengraph {
    title       = "AWS Thrifty Mod for Flowpipe"
    description = "Run pipelines to remediate AWS resources that are unused and underutilized."
    image       = "/images/mods/turbot/aws-social-graphic.png"
  }

  require {
    mod "github.com/turbot/flowpipe-mod-aws" {
      version = "v0.2.0"
    }
    mod "github.com/turbot/flowpipe-mod-detect-correct" {
      version = "*"
    }
  }
}