# Correct one EBS volume using gp2

## Overview

EBS gp2 volumes are more expensive and less performant than gp3 volumes.

This pipeline allows you to specify a single gp2 EBS volume and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_ebs_volumes_using_gp2 pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.correct_ebs_volumes_using_gp2).