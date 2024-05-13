# Correct ElastiCache clusters exceeding max age

## Overview

ElastiCache clusters incur ongoing costs, so it's important to retire clusters that surpass a certain age to optimize resource use and minimize unnecessary expenses.

This pipeline allows you to specify a collection of ElastiCache clusters exceeding the maximum age and then either sends notifications or attempts to perform a predefined corrective action upon the collection.

While this pipeline can be used independently, it is typically invoked from either:
- [detect_and_correct_elasticache_clusters_exceeding_max_age pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_elasticache_clusters_exceeding_max_age)
- [detect_and_correct_elasticache_clusters_exceeding_max_age trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_elasticache_clusters_exceeding_max_age)
