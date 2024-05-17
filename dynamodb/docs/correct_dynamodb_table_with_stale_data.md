# Correct DynamoDB tables with stale data

## Overview

DynamoDB tables can be quite costly to retain, it is also likely that after a certain point in time they're no longer required and should be cleaned up to prevent further costs.

This pipeline allows you to specify a collection of DynamoDB tables and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_dynamodb_table_with_stale_data pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_dynamodb_table_with_stale_data)
- [detect_and_correct_dynamodb_table_with_stale_data trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_dynamodb_table_with_stale_data)