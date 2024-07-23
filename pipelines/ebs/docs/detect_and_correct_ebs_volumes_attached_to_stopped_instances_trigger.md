# Detect & correct EBS volumes attached to stopped instances

## Overview

EBS volumes attached to stopped instances still incur costs even though they may not be used; these should be reviewed and either detached from the stopped instance or deleted.

This query trigger detects EBS volumes attached to stopped instances and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configred by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `ebs_volumes_attached_to_stopped_instances_trigger_enabled` should be set to `true` as the default is `false`.
- `ebs_volumes_attached_to_stopped_instances_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `ebs_volumes_attached_to_stopped_instances_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"detach_volume"` to detach the volume from the instance).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```