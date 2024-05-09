## Overview

This pipeline allows you to specify a collection of unattached Elastic IP addresses and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone (see below), it is usually called from either:
- [detect_and_correct_vpc_eips_unattached pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_vpc_eips_unattached)
- [detect_and_correct_vpc_eips_unattached trigger](https://hub.flowpipe.io/mods/turbot/aws-thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_vpc_eips_unattached)