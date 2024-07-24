# Detect & correct Route53 records with lower TTL

## Overview

Route53 records with a lower TTL result in more DNS queries being received and answered than those with a higher TTL, which in turn results in more costs - common approaches for a TTL are between 3600s (one hour) and 86,400s (one day).

This pipeline detects records with a lower TTL and then either sends a notification or attempts to perform a predefined corrective action.

## Getting Started

This control will work out-of-the-box with some sensible defaults (configurable via [variables](https://flowpipe.io/docs/build/mod-variables)).

You should be able to simply run the following command in your terminal:
```sh
flowpipe pipeline run detect_and_correct_route53_records_with_lower_ttl
```

By default, Flowpipe runs in [wizard](https://hub.flowpipe.io/mods/turbot/aws_thrifty#wizard) mode and prompts directly in the terminal for a decision on the action(s) to take for each detected resource.

However, you can run Flowpipe in [server](https://flowpipe.io/docs/run/server) mode with [external integrations](https://flowpipe.io/docs/build/input#create-an-integration), allowing it to prompt for input via `http`, `slack`, `teams`, etc.

Alternatively, you can choose to configure and run in other modes:
* [notify](https://hub.flowpipe.io/mods/turbot/aws_thrifty#notify): Provides detections without taking any corrective action.
* [automatic](https://hub.flowpipe.io/mods/turbot/aws_thrifty#automatic): Performs corrective actions automatically without user intervention.