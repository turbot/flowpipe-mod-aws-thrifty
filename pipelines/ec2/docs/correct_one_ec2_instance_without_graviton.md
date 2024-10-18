## Overview

EC2 instances without graviton processor incur cost over time, so it's crucial to delete instances without the graviton processor to optimize expenses.

This pipeline allows you to specify a single EC2 instance without graviton processor and then either sends a notification or attempts to perform a predefined corrective action.

While this pipeline can instance independently, it is typically invoked from the [correct_ec2_instances_without_graviton pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_ec2_instances_without_graviton).
