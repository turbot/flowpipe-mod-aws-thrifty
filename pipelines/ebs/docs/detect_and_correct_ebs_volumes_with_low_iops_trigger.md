# Detect & correct EBS volumes with low IOPS

## Overview

EBS volumes with lower than 16k base IOPS should be using gp3 rather than the more costly io1/io2 volumes types.

This query trigger detects io type EBS volumes with low IOPS and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configred by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `ebs_volumes_with_low_iops_trigger_enabled` should be set to `true` as the default is `false`.
- `ebs_volumes_with_low_iops_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `ebs_volumes_with_low_iops_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"delete_volume"` to delete the volume).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```