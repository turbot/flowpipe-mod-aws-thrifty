## Overview

EBS gp2 volumes are more expensive and less performant than gp3 volumes.

This query trigger detects gp2 EBS volumes and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `ebs_volumes_using_gp2_trigger_enabled` should be set to `true` as the default is `false`.
- `ebs_volumes_using_gp2_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `ebs_volumes_using_gp2_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"update_to_gp3"` to update the volume).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```