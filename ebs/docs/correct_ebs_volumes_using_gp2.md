# Correct EBS volumes using gp2

## Overview

EBS gp2 volumes are more expensive and less performant than gp3 volumes.

This pipeline allows you to specify a collection of gp2 EBS volumes and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_ebs_volumes_using_gp2_trigger pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_ebs_volumes_using_gp2_trigger)
- [detect_and_correct_ebs_volumes_using_gp2_trigger trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ebs_volumes_using_gp2_trigger)