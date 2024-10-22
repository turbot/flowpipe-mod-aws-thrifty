## Overview

Amazon EC2 classic load balancers with no instances attached still cost money and should be deleted.

This pipeline allows you to specify a collection of EC2 classic load balancers with no instances attached and either sends notifications or attempts to perform predefined corrective actions upon the collection.

Whilst it is possible to utilize this pipeline standalone, it is usually called from either:

- [detect_and_correct_ec2_classic_load_balancers_if_unused pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_ec2_classic_load_balancers_if_unused)
- [detect_and_correct_ec2_classic_load_balancers_if_unused trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ec2_classic_load_balancers_if_unused)
