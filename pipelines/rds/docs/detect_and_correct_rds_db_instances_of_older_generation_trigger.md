# Detect & correct RDS DB instances of older generation

## Overview

Older generation instance types are more expensive and less performant than the current generation equivalents, you should be using the latest generation to reduce costs and increase performance. 

This query trigger detects older generation RDS instances and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `rds_db_instances_of_older_generation_trigger_enabled` should be set to `true` as the default is `false`.
- `rds_db_instances_of_older_generation_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `rds_db_instances_of_older_generation_trigger_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"delete_instance"` to delete the health check).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```