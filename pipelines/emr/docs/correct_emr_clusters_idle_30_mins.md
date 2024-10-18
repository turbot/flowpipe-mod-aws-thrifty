## Overview

EMR clusters which are live but not currently running tasks should be reviewed and checked whether the cluster has been idle for more than 30 minutes

This pipeline allows you to specify a collection of EMR clusters idle for more than 30 mins and then either sends notifications or attempts to perform a predefined corrective action upon the collection.

While this pipeline can be used independently, it is typically invoked from either:
- [detect_and_correct_emr_clusters_idle_30_mins pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_emr_clusters_idle_30_mins)
- [detect_and_correct_emr_clusters_idle_30_mins trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_emr_clusters_idle_30_mins)
