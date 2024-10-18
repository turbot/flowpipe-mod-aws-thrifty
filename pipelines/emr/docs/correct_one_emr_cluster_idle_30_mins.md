## Overview

EMR clusters incur cost over time, so it's crucial to delete clusters that have been idle for more than 30 minutes.

This pipeline allows you to specify a single EMR cluster idle for more than 30 minutes and then either sends a notification or attempts to perform a predefined corrective action.

While this pipeline can function independently, it is typically invoked from the [correct_emr_clusters_idle_30_mins pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_emr_clusters_idle_30_mins).
