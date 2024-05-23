# Correct EC2 instances with low utilization

## Overview

Amazon EC2 instances with low utilization should be reviewed for either down-sizing or stopping if no longer required in order to reduce running costs.

This pipeline allows you to specify a collection of EC2 instances and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_ec2_instances_with_low_utilization pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_ec2_instances_with_low_utilization)
- [detect_and_correct_ec2_instances_with_low_utilization trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ec2_instances_with_low_utilization)