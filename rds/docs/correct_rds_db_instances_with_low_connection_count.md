# Correct RDS DB instances with low connection count

## Overview

RDS instances can be costly to run, especially if they're rarely used, instances with low average connection counts per day should be reviewed to determine if they're still required.

This pipeline allows you to specify a collection of instances and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_rds_db_instances_with_low_connection_count pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_rds_db_instances_with_low_connection_count)
- [detect_and_correct_rds_db_instances_with_low_connection_count trigger](https://hub.flowpipe.io/mods/turbot/aws-thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_rds_db_instances_with_low_connection_count)