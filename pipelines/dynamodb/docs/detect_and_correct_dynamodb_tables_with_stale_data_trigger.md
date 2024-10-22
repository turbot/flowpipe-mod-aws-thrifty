## Overview

DynamoDB table data can be quite costly to retain, it is also likely that after a certain point in time they're no longer required and should be cleaned up to prevent further costs.

This query trigger detects unused health checks and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `dynamodb_tables_with_stale_data_trigger_enabled` should be set to `true` as the default is `false`.
- `dynamodb_tables_with_stale_data_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `dynamodb_tables_with_stale_data_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"delete_table"` to delete the table).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```