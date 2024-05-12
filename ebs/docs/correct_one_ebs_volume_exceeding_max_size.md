# Correct one EBS volume exceeding max size

## Overview

Excessively large EBS volumes accrue high costs and usually aren't required to be so large, these should be reviewed and if not required removed.

This pipeline allows you to specify a single EBS volume and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_ebs_volumes_exceeding_max_size pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.correct_ebs_volumes_exceeding_max_size).