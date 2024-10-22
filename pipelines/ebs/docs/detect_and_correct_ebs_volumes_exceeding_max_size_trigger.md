## Overview

Excessively large EBS volumes accrue high costs and usually aren't required to be so large, these should be reviewed and if not required removed.

This query trigger detects EBS volumes exceeding a predetermined capacity and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `ebs_volumes_exceeding_max_size_trigger_enabled` should be set to `true` as the default is `false`.
- `ebs_volumes_exceeding_max_size_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `ebs_volumes_exceeding_max_size_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"snapshot_and_delete_volume"` to snapshot and then delete the volume).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```