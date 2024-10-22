## Overview

RDS DB Instances that run for a long time should either be associated with a Reserved Instance or removed to reduce costs.

This pipeline allows you to specify a single long running RDS instance and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_rds_db_instances_exceeding_max_age pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_rds_db_instances_exceeding_max_age).