# Detect & correct RDS DB instances without graviton processor

## Overview

RDS instances running non-graviton processors are likely to incur higher charges, these should be reviewed.

This query trigger detects non-graviton based instances and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `rds_db_instances_without_graviton_trigger_enabled` should be set to `true` as the default is `false`.
- `rds_db_instances_without_graviton_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `rds_db_instances_without_graviton_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"delete_instance"` to delete the instance).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```