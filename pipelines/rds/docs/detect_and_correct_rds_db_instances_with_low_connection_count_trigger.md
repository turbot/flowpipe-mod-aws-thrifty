## Overview

RDS instances can be costly to run, especially if they're rarely used, instances with low average connection counts per day should be reviewed to determine if they're still required.

This query trigger detects RDS instances with low average daily connections and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `rds_db_instances_with_low_connection_count_trigger_enabled` should be set to `true` as the default is `false`.
- `rds_db_instances_with_low_connection_count_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `rds_db_instances_with_low_connection_count_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"delete_instance"` to delete the instance).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```