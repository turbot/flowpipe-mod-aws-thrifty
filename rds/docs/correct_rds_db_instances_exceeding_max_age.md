# Correct RDS DB instances exceeding max age

## Overview

RDS DB Instances that run for a long time should either be associated with a Reserved Instance or removed to reduce costs.

This pipeline allows you to specify a collection of long running RDS instances and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_rds_db_instances_exceeding_max_age pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_rds_db_instances_exceeding_max_age)
- [detect_and_correct_rds_db_instances_exceeding_max_age trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_rds_db_instances_exceeding_max_age)
