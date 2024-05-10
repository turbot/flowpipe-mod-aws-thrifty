# Correct Route53 records with lower TTL

## Overview

Route53 records with a lower TTL result in more DNS queries being received and answered than those with a higher TTL, which in turn results in more costs - common approaches for a TTL are between 3600s (one hour) and 86,400s (one day).

This pipeline allows you to specify a collection of records with a lower TTL and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_route53_records_with_lower_ttl pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_route53_records_with_lower_ttl)
- [detect_and_correct_route53_records_with_lower_ttl trigger](https://hub.flowpipe.io/mods/turbot/aws-thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_route53_records_with_lower_ttl)