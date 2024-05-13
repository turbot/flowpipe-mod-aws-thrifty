# Correct RDS DB instances without graviton processor

## Overview

RDS instances running non-graviton processors are likely to incur higher charges, these should be reviewed.

This pipeline allows you to specify a collection of non-graviton based instances and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_rds_db_instances_without_graviton pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_rds_db_instances_without_graviton)
- [detect_and_correct_rds_db_instances_without_graviton trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_rds_db_instances_without_graviton)