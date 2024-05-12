# Correct one Lambda function without graviton processor

## Overview

Lambda functions without graviton processor incur cost over time, so it's crucial to delete functions without the graviton processor to optimize expenses.

This pipeline allows you to specify a single Lambda function without graviton processor and then either sends a notification or attempts to perform a predefined corrective action.

While this pipeline can function independently, it is typically invoked from the [correct_lambda_functions_without_graviton pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.correct_lambda_functions_without_graviton).
