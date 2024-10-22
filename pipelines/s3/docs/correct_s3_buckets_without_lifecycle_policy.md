## Overview

S3 Buckets without a lifecycle policy will not move objects between storage layers or expire objects, causing them to remain in their initial tier perpetually, this is inefficient and can be costly.

This pipeline allows you to specify a collection of S3 buckets without lifecycle policies and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone (see below), it is usually called from either:
- [detect_and_correct_s3_buckets_without_lifecycle_policy pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_s3_buckets_without_lifecycle_policy)
- [detect_and_correct_s3_buckets_without_lifecycle_policy trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_s3_buckets_without_lifecycle_policy)