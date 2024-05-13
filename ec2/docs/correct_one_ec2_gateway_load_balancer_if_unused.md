# Correct one EC2 gateway load balancer if unused

## Overview

Amazon EC2 gateway load balancers with no targets attached still cost money and should be deleted.

This pipeline allows you to specify a collection of EC2 gateway load balancers with no targets attached and either sends notifications or attempts to perform predefined corrective actions upon the collection.

Whilst it is possible to utilize this pipeline standalone, it is usually called from the [correct_one_ec2_gateway_load_balancer_if_unused pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_one_ec2_gateway_load_balancer_if_unused).
