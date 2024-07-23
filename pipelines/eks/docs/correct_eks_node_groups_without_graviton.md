# Correct EKS node groups without Graviton

## Overview

Amazon EKS node groups that don't use Graviton processor may incur higher costs compared to those that do. Switching to Graviton processor can help reduce your operational expenses.

This pipeline allows you to specify a collection of non-Graviton EKS node groups and either sends notifications or attempts to perform predefined corrective actions upon the collection.

Whilst it is possible to utilize this pipeline standalone, it is usually called from either:

- [detect_and_correct_eks_node_groups_without_graviton pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.detect_and_correct_eks_node_groups_without_graviton)
- [detect_and_correct_eks_node_groups_without_graviton trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_eks_node_groups_without_graviton)
