## Overview

Lambda functions without graviton processor incur cost over time, with graviton processor (arm64 - 64-bit ARM architecture), you can save money in two ways: First, your functions run more efficiently due to the Graviton architecture. Second, you pay less for the time that they run. In fact, Lambda functions powered by Graviton are designed to deliver up to 19 percent better performance at 20 percent lower cost.

This pipeline allows you to specify a collection of Lambda functions without the graviton processor and then either sends notifications or attempts to perform a predefined corrective action upon the collection.

While this pipeline can be used independently, it is typically invoked from either:
- [detect_and_correct_lambda_functions_without_graviton pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_lambda_functions_without_graviton)
- [detect_and_correct_lambda_functions_without_graviton trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_lambda_functions_without_graviton)
