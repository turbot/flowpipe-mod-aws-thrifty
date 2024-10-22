mod "aws_thrifty" {
  title         = "AWS Thrifty"
  description   = "Run pipelines to detect and correct AWS resources that are unused and underutilized."
  color         = "#FF9900"
  documentation = file("./README.md")
  icon          = "/images/mods/turbot/aws-thrifty.svg"
  categories    = ["aws", "cost", "public cloud", "standard", "thrifty"]
  database      = var.database

  opengraph {
    title       = "AWS Thrifty Mod for Flowpipe"
    description = "Run pipelines to detect and correct AWS resources that are unused and underutilized."
    image       = "/images/mods/turbot/aws-thrifty-social-graphic.png"
  }

  require {
    flowpipe {
      min_version = "1.0.0"
    }
    mod "github.com/turbot/flowpipe-mod-aws" {
      version = "^1"
    }
    mod "github.com/turbot/flowpipe-mod-detect-correct" {
      version = "^1"
    }
  }
}
