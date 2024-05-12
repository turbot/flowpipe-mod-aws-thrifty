# Correct one EBS volume using io1

## Overview

EBS io1 volumes are less reliable than io2 volumes for the same cost.

This pipeline allows you to specify a single io1 EBS volume and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_ebs_volumes_using_io1 pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.correct_ebs_volumes_using_io1).