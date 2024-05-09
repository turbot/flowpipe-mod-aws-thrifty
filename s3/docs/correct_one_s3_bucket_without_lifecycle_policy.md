## Overview

This pipeline allows you to specify a single S3 bucket without a lifecycle policy and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone (see below), it is usually called from the [correct_s3_buckets_without_lifecycle_policy pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.correct_s3_buckets_without_lifecycle_policy)