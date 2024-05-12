# Correct one VPC NAT gateway if unused

## Overview

NAT gateways are charged per hour once they are provisioned and available, so unused gateways should be deleted to prevent costs.

This pipeline allows you to specify a single unused NAT gateway and then either sends a notification or attempts to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_vpc_nat_gateways_if_unused pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.correct_vpc_nat_gateways_if_unused).