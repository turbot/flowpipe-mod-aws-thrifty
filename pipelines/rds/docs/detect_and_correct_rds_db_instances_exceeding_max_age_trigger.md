# Detect & correct RDS DB instances exceeding max age

## Overview

RDS DB Instances that run for a long time should either be associated with a Reserved Instance or removed to reduce costs.

This query trigger detects RDS instances that have been running for a long time and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configred by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `rds_db_instances_exceeding_max_age_trigger_enabled` should be set to `true` as the default is `false`.
- `rds_db_instances_exceeding_max_age_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `rds_db_instances_exceeding_max_age_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"delete_instance"` to delete the instance).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```