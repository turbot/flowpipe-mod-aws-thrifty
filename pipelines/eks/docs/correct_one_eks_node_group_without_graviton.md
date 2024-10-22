## Overview

Amazon EKS node groups not using Graviton processor may incur higher costs compared to those that do. Therefore, switching to Graviton processor can reduce operational expenses.

This pipeline allows you to specify a single non-Graviton EKS node group and then either sends a notification or attempts to perform a predefined corrective action.

Whilst it is possible to utilize this pipeline standalone, it is usually called from the [correct_eks_node_groups_without_graviton pipeline](https://hub.flowpipe.io/mods/turbot/aws_thrifty/pipelines/aws_thrifty.pipeline.correct_eks_node_groups_without_graviton).
