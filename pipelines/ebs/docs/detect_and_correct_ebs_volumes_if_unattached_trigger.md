## Overview

EBS volumes which are not attached will still incur charges and provide no real use, these volumes should be reviewed and if necessary tidied up.

This query trigger detects unattached EBS volumes and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `ebs_volumes_if_unattached_trigger_enabled` should be set to `true` as the default is `false`.
- `ebs_volumes_if_unattached_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `ebs_volumes_if_unattached_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"snapshot_and_delete_volume"` to snapshot and then delete the volume).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```