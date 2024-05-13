# Correct one EBS volume with low IOPS

## Overview

EBS volumes with lower than 16k base IOPS should be using gp3 rather than the more costly io1/io2 volumes types.

This pipeline allows you to specify a single io type EBS volume with low IOPS and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_ebs_volumes_with_low_iops pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_ebs_volumes_with_low_iops).