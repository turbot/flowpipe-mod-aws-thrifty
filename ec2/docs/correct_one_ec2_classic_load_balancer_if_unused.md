# Correct one EC2 classic load balancer if unused

## Overview

Amazon EC2 classic load balancers with no instances attached still cost money and should be deleted.

This pipeline allows you to specify a collection of EC2 classic load balancers with no instances attached and either sends notifications or attempts to perform predefined corrective actions upon the collection.

Whilst it is possible to utilize this pipeline standalone, it is usually called from the [correct_one_ec2_classic_load_balancer_if_unused pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.correct_one_ec2_classic_load_balancer_if_unused).
