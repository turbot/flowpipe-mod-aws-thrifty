# Detect & correct EC2 instances with low utilization

## Overview

Amazon EC2 instances with low utilization should be reviewed for either down-sizing or stopping if no longer required in order to reduce running costs. 

This query trigger identifies EC2 instances with low utilization and either sends notifications or attempts predefined corrective actions.

### Getting Started

By default, this trigger is disabled, but can be configured by [setting the variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables):

- `ec2_instances_with_low_utilization_trigger_enabled` should be set to `true` (default is `false`).
- `ec2_instances_with_low_utilization_trigger_schedule` should be set according to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples).
- `ec2_instances_with_low_utilization_default_action` should be set to `"notify"` or any other desired action (e.g., `"notify"` for notifications or `"stop_instance"` to stop the instance).

Then starting the server:

```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:

```sh
flowpipe server --var-file=/path/to/your.fpvars
```
