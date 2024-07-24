# Detect & correct EC2 instances of older generation

## Overview

Older generation instance types are more expensive and less performant than the current generation equivalents, you should be using the latest generation to reduce costs and increase performance. 

This query trigger detects older generation EC2 instances and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `ec2_instances_of_older_generation_trigger_enabled` should be set to `true` as the default is `false`.
- `ec2_instances_of_older_generation_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `ec2_instances_of_older_generation_trigger_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"terminate_instance"` to delete the instance).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```