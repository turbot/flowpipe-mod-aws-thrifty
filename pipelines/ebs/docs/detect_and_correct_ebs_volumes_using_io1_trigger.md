## Overview

EBS io1 volumes are less reliable than io2 volumes for the same cost.

This query trigger detects io1 EBS volumes and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `ebs_volumes_using_io1_trigger_enabled` should be set to `true` as the default is `false`.
- `ebs_volumes_using_io1_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `ebs_volumes_using_io1_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"update_to_io2"` to update the volume).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```