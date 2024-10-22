## Overview

ElastiCache clusters incur costs over time, so it's crucial to retire clusters that exceed a certain age to optimize expenses.

This pipeline allows you to specify a single ElastiCache cluster exceeding the maximum age and then either sends a notification or attempts to perform a predefined corrective action.

While this pipeline can function independently, it is typically invoked from the [correct_elasticache_clusters_exceeding_max_age pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_elasticache_clusters_exceeding_max_age).
