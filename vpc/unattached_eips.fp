
/*
 * See same thing multiple days?
 * Approval flow? Check then act, act if not stopped, etc?
 * How to enable lots of them? e.g. all of thrifty
 * Post to a shared Slack channel.
 * No approval required: disable wiki, add key topics, branch protection.
 * Notifications: when you did something, when you checked but had nothing to do (until I trust it / get sick of the noise), I tried to check but got an error.
 * Batch or don't batch? I think batch for manual, don't batch for triggers (by default).
 */

trigger "unattached_eips" {

  sql = file("../queries/find_unattached_eips.sql")

  capture "insert" {
    pipeline = pipeline.handle_unattached_eips
    args = {
      items = self.inserted_rows
    }
  }

}


pipeline "vpc_unattached_eips" {

  step "query" "find_unattached_eips" {
    sql = file("../queries/find_unattached_eips.sql")
  }

  step "pipeline" "handle_unattached_eips" {
    pipeline = pipeline.handle_unattached_eips
    args = {
      items = step.query.find_unattached_eips.rows
    }
  }

}


pipeline "handle_unattached_eips" {

  param "items" {
    type = list(any)
  }

  step "pipeline" "handle" {
    for_each = param.items
    max_concurrency = 1
    pipeline = pipeline.handle_unattached_eip
  }

}


pipeline "handle_unattached_eip" {

  param "item" {
    type = any
  }

  step "pipeline" "approve" {
    pipeline = approve.pipeline.approve
  }

  step "pipeline" "delete" {
    if = step.pipeline.approve.output.approved
    pipeline = aws.pipeline.release_elastic_ip
    args = param.item
  }

  step "message" "notify" {
    if = step.pipeline.approve.output.approved
    text = "Elastic IP address with allocation ID ${param.item.allocation_id} has been released."
  }

}


pipeline "release_elastic_ip" {
  title       = "Release Elastic IP Address"
  description = "Releases a specified Elastic IP address."

  param "region" {
    type        = string
    description = local.region_param_description
  }

  param "cred" {
    type        = string
    description = local.cred_param_description
    default     = "default"
  }

  param "allocation_id" {
    type        = string
    description = "The allocation ID of the Elastic IP address to release."
  }

  step "container" "release_elastic_ip" {
    image = "public.ecr.aws/aws-cli/aws-cli"
    cmd = ["ec2", "release-address", "--allocation-id", param.allocation_id]
    env = merge(credential.aws[param.cred].env, { AWS_REGION = param.region })
  }

  output "eips" {
    description = "Confirmation of the Elastic IP address release."
    value       = "Elastic IP address with allocation ID ${param.allocation_id} has been released."
  }
}

