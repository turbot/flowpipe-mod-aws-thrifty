## Overview

NAT gateways are charged per hour once they are provisioned and available, so unused gateways should be deleted to prevent costs.

This pipeline allows you to specify a collection of unused NAT gateways and then either sends a notification or attempts to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_vpc_nat_gateways_if_unused pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_vpc_nat_gateways_if_unused)
- [detect_and_correct_vpc_nat_gateways_if_unused trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_vpc_nat_gateways_if_unused)