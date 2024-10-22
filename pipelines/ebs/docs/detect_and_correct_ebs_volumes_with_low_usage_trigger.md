## Overview

EBS volumes with low usage may be indicative that they're no longer required, these should be reviewed.

This query trigger detects EBS volumes with low average usage and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `ebs_volumes_with_low_usage_trigger_enabled` should be set to `true` as the default is `false`.
- `ebs_volumes_with_low_usage_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `ebs_volumes_with_low_usage_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"delete_volume"` to update the volume).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```