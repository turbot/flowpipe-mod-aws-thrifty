# Correct EC2 application load balancers if unused

## Overview

Amazon EC2 application load balancers with no targets attached still cost money and should be deleted.

This pipeline allows you to specify a collection of EC2 application load balancers and either sends notifications or attempts to perform predefined corrective actions upon the collection.

Whilst it is possible to utilize this pipeline standalone, it is usually called from either:

- [detect_and_correct_ec2_application_load_balancers_if_unused pipeline](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_ec2_application_load_balancers_if_unused)
- [detect_and_correct_ec2_application_load_balancers_if_unused trigger](https://hub.flowpipe.io/mods/turbot/aws-thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ec2_application_load_balancers_if_unused)
