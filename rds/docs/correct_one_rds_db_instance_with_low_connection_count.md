# Correct one RDS DB instance with low connection count

RDS instances can be costly to run, especially if they're rarely used, instances with low average connection counts per day should be reviewed to determine if they're still required.

This pipeline allows you to specify a single instance and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_rds_db_instances_with_low_connection_count pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.correct_rds_db_instances_with_low_connection_count).