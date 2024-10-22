## Overview

EBS volumes which are not attached will still incur charges and provide no real use, these volumes should be reviewed and if necessary tidied up.

This pipeline detects unattached EBS volumes and then either sends a notification or attempts to perform a predefined corrective action.

## Getting Started

This control will work out-of-the-box with some sensible defaults (configurable via [variables](https://flowpipe.io/docs/build/mod-variables)).

You should be able to simply run the following command in your terminal:
```sh
flowpipe pipeline run detect_and_correct_ebs_volumes_if_unattached
```

By default, Flowpipe runs in [wizard](https://hub.flowpipe.io/mods/turbot/aws_thrifty#wizard) mode and prompts directly in the terminal for a decision on the action(s) to take for each detected resource.

However, you can run Flowpipe in [server](https://flowpipe.io/docs/run/server) mode with [external integrations](https://flowpipe.io/docs/build/input#create-an-integration), allowing it to prompt for input via `http`, `slack`, `teams`, etc.

Alternatively, you can choose to configure and run in other modes:
* [Notify](https://hub.flowpipe.io/mods/turbot/aws_thrifty#notify): Provides detections without taking any corrective action.
* [Automatic](https://hub.flowpipe.io/mods/turbot/aws_thrifty#automatic): Performs corrective actions automatically without user intervention.