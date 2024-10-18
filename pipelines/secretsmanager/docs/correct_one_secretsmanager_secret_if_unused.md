## Overview

SecretsManager secrets have an inherent monthly cost, therefore secrets which are no longer accessed / used should be removed to prevent further charges.

This pipeline allows you to specify a single unused secret and then either sends a notification or attempts to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_secretsmanager_secrets_if_unused pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_secretsmanager_secrets_if_unused).
