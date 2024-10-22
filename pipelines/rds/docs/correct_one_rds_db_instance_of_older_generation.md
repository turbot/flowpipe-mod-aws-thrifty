## Overview

Older generation instance types are more expensive and less performant than the current generation equivalents, you should be using the latest generation to reduce costs and increase performance. 

This pipeline allows you to specify a RDS instances and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_rds_db_instances_of_older_generation pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_rds_db_instances_of_older_generation).