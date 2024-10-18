## Overview

EBS volumes which are not attached will still incur charges and provide no real use, these volumes should be reviewed and if necessary tidied up.

This pipeline allows you to specify a single unattached EBS volume and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_ebs_volumes_if_unattached pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_ebs_volumes_if_unattached).