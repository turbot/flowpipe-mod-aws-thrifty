# Correct EBS volumes using io1

## Overview

EBS io1 volumes are less reliable than io2 volumes for the same cost.

This pipeline allows you to specify a collection of io1 EBS volumes and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_ebs_volumes_using_io1_trigger pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_ebs_volumes_using_io1_trigger)
- [detect_and_correct_ebs_volumes_using_io1_trigger trigger](https://hub.flowpipe.io/mods/turbot/aws-thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ebs_volumes_using_io1_trigger)