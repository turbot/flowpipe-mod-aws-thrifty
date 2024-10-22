## Overview

Amazon EKS node groups that don't use Graviton processor can incur higher operational costs. This pipeline detects non-Graviton EKS node groups and either sends a notification or attempts to perform a predefined corrective action.

## Getting Started

This control works out-of-the-box with sensible defaults, configurable via [variables](https://flowpipe.io/docs/build/mod-variables).

You should be able to simply run the following command in your terminal:

```sh
flowpipe pipeline run detect_and_correct_eks_node_groups_without_graviton
```

By default, Flowpipe runs in [wizard](https://hub.flowpipe.io/mods/turbot/aws_thrifty#wizard) mode and prompts directly in the terminal for a decision on the action(s) to take for each detected resource.

However, you can run Flowpipe in [server](https://flowpipe.io/docs/run/server) mode with [external integrations](https://flowpipe.io/docs/build/input#create-an-integration), allowing it to prompt for input via `http`, `slack`, `teams`, etc.

Alternatively, you can choose to configure and run in other modes:
* [Notify](https://hub.flowpipe.io/mods/turbot/aws_thrifty#notify): Provides detections without taking any corrective action.
* [Automatic](https://hub.flowpipe.io/mods/turbot/aws_thrifty#automatic): Performs corrective actions automatically without user intervention.