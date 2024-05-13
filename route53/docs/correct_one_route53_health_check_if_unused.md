# Correct one Route53 health check if unused

## Overview

Route53 health checks have an associated monthly cost, therefore those which are no longer required should be removed to prevent further charges.

This pipeline allows you to specify a single unused health check and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_route53_health_checks_if_unused pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_route53_health_checks_if_unused).