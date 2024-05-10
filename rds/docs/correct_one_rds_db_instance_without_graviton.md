# Correct one RDS DB instance without graviton processor

## Overview

RDS instances running non-graviton processors are likely to incur higher charges, these should be reviewed.

This pipeline allows you to specify a single non-graviton instance and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_rds_db_instances_without_graviton pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.correct_rds_db_instances_without_graviton).