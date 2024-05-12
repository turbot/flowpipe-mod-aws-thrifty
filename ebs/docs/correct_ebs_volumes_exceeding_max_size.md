# Correct EBS volumes exceeding max size

## Overview

Excessively large EBS volumes accrue high costs and usually aren't required to be so large, these should be reviewed and if not required removed.

This pipeline allows you to specify a collection of EBS volume and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_ebs_volumes_exceeding_max_size_trigger pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_ebs_volumes_exceeding_max_size_trigger)
- [detect_and_correct_ebs_volumes_exceeding_max_size_trigger trigger](https://hub.flowpipe.io/mods/turbot/aws-thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ebs_volumes_exceeding_max_size_trigger)