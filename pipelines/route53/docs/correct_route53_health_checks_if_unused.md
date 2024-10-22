## Overview

Route53 health checks have an associated monthly cost, therefore those which are no longer required should be removed to prevent further charges.

This pipeline allows you to specify a collection of unused health checks and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_route53_health_checks_if_unused pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_route53_health_checks_if_unused)
- [detect_and_correct_route53_health_checks_if_unused trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_route53_health_checks_if_unused)