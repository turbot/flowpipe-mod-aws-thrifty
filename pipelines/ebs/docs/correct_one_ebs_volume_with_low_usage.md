## Overview

EBS volumes with low usage may be indicative that they're no longer required, these should be reviewed.

This pipeline allows you to specify a single EBS volume with low usage and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_ebs_volumes_with_low_usage pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_ebs_volumes_with_low_usage).