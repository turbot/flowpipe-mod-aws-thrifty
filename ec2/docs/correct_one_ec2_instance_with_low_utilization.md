# Correct one EC2 instance with low utilization

## Overview

Amazon EC2 instances with low utilization should be reviewed for either down-sizing or stopping if no longer required in order to reduce running costs.

This pipeline allows you to specify a EC2 instances and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_ec2_instances_with_low_utilization pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_ec2_instances_with_low_utilization).