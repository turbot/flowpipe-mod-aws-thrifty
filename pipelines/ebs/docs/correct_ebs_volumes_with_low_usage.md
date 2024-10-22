## Overview

EBS volumes with low usage may be indicative that they're no longer required, these should be reviewed.

This pipeline allows you to specify a collection of EBS volumes with low usage and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_ebs_volumes_with_low_usage_trigger pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_ebs_volumes_with_low_usage_trigger)
- [detect_and_correct_ebs_volumes_with_low_usage_trigger trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ebs_volumes_with_low_usage_trigger)