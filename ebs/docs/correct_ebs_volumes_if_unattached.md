# Correct EBS volumes if unattached

## Overview

EBS volumes which are not attached will still incur charges and provide no real use, these volumes should be reviewed and if necessary tidied up.

This pipeline allows you to specify a collection of unattached EBS volumes and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_ebs_volumes_if_unattached_trigger pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_ebs_volumes_if_unattached_trigger)
- [detect_and_correct_ebs_volumes_if_unattached_trigger trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ebs_volumes_if_unattached_trigger)