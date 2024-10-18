## Overview

Older generation instance types are more expensive and less performant than the current generation equivalents, you should be using the latest generation to reduce costs and increase performance. 

This pipeline allows you to specify a collection of EC2 instances and then either send notifications or attempt to perform a predefined corrective action upon the collection.

Whilst it is possible to utilise this pipeline standalone, it is usually called from either:
- [detect_and_correct_ec2_instances_of_older_generation pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_ec2_instances_of_older_generation)
- [detect_and_correct_ec2_instances_of_older_generation trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ec2_instances_of_older_generation)