# Correct one Route53 record with lower TTL

## Overview

Route53 records with a lower TTL result in more DNS queries being received and answered than those with a higher TTL, which in turn results in more costs - common approaches for a TTL are between 3600s (one hour) and 86,400s (one day).

This pipeline allows you to specify a single record and then either send a notification or attempt to perform a predefined corrective action.

Whilst it is possible to utilise this pipeline standalone, it is usually called from the [correct_route53_records_with_lower_ttl pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_route53_records_with_lower_ttl).