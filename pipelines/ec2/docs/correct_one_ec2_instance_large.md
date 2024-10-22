## Overview

EC2 instances can be quite costly to retain, it is also likely that after a certain point in time they're no longer required and should be cleaned up to prevent further costs. Large EC2 instances are unusual, expensive and should be reviewed.

This pipeline allows you to specify a single large EC2 instance and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_ec2_instances_large pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_ec2_instances_large).