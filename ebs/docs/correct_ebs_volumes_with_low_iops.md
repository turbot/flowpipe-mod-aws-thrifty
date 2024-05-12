# Correct EBS volumes with low IOPS

## Overview

EBS volumes with lower than 16k base IOPS should be using gp3 rather than the more costly io1/io2 volumes types.

This pipeline allows you to specify a collection of io type EBS volumes with low IOPS and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_ebs_volumes_with_low_iops_trigger pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_ebs_volumes_with_low_iops_trigger)
- [detect_and_correct_ebs_volumes_with_low_iops_trigger trigger](https://hub.flowpipe.io/mods/turbot/aws-thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ebs_volumes_with_low_iops_trigger)