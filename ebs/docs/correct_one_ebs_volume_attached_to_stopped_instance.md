# Correct EBS volumes attached to stopped instances

## Overview

EBS volumes attached to stopped instances still incur costs even though they may not be used; these should be reviewed and either detached from the stopped instance or deleted.

This pipeline allows you to specify a single EBS volume and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_ebs_volumes_attached_to_stopped_instances pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_ebs_volumes_attached_to_stopped_instances).