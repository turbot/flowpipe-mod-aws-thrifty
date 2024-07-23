# Detect & correct large EC2 instances

## Overview

EC2 instances can be quite costly to retain, it is also likely that after a certain point in time they're no longer required and should be cleaned up to prevent further costs. Large EC2 instances are unusual, expensive and should be reviewed.

This query trigger detects large EC2 instances and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configred by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `ec2_instances_large_trigger_enabled` should be set to `true` as the default is `false`.
- `ec2_instances_large_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `ec2_instances_large_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"terminate_instance"` to delete the instance).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```