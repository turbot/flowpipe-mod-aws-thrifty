# Correct EBS volumes attached to stopped instances

## Overview

EBS volumes attached to stopped instances still incur costs even though they may not be used; these should be reviewed and either detached from the stopped instance or deleted.

This pipeline allows you to specify a collection of EBS volume and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_ebs_volumes_attached_to_stopped_instances_trigger pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_ebs_volumes_attached_to_stopped_instances_trigger)
- [detect_and_correct_ebs_volumes_attached_to_stopped_instances_trigger trigger](https://hub.flowpipe.io/mods/turbot/aws-thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ebs_volumes_attached_to_stopped_instances_trigger)