# Correct EC2 instances if large

## Overview

EC2 instances can be quite costly to retain, it is also likely that after a certain point in time they're no longer required and should be cleaned up to prevent further costs. Large EC2 instances are unusual, expensive and should be reviewed.

This pipeline allows you to specify a collection of large EC2 instances and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_ec2_instances_large pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_ec2_instances_large)
- [detect_and_correct_ec2_instances_large trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ec2_instances_large)