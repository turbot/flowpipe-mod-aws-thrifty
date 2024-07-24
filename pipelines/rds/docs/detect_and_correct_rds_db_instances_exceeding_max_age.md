# Detect & correct RDS DB instances exceeding max age

## Overview

RDS DB Instances that run for a long time should either be associated with a Reserved Instance or removed to reduce costs.

This pipeline detects RDS instances that have been running for a long time and then either sends a notification or attempts to perform a predefined corrective action.

## Getting Started

This control will work out-of-the-box with some sensible defaults (configurable via [variables](https://flowpipe.io/docs/build/mod-variables)).

You should be able to simply run the following command in your terminal:
```sh
flowpipe pipeline run detect_and_correct_rds_db_instances_exceeding_max_age
```

By default, Flowpipe runs in [wizard](https://hub.flowpipe.io/mods/turbot/aws_thrifty#wizard) mode and prompts directly in the terminal for a decision on the action(s) to take for each detected resource.

However, you can run Flowpipe in [server](https://flowpipe.io/docs/run/server) mode with [external integrations](https://flowpipe.io/docs/build/input#create-an-integration), allowing it to prompt for input via `http`, `slack`, `teams`, etc.

Alternatively, you can choose to configure and run in other modes:
* [notify](https://hub.flowpipe.io/mods/turbot/aws_thrifty#notify): Provides detections without taking any corrective action.
* [automatic](https://hub.flowpipe.io/mods/turbot/aws_thrifty#automatic): Performs corrective actions automatically without user intervention.