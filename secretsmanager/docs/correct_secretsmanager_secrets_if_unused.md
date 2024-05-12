# Correct SecretsManager secrets if unused

## Overview

SecretsManager secrets have an inherent monthly cost, therefore secrets which are no longer accessed / used should be removed to prevent further charges.

This pipeline allows you to specify a collection of unused secrets and then either sends notifications or attempts to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_secretsmanager_secrets_if_unused pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_secretsmanager_secrets_if_unused)
- [detect_and_correct_secretsmanager_secrets_if_unused trigger](https://hub.flowpipe.io/mods/turbot/aws-thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_secretsmanager_secrets_if_unused)