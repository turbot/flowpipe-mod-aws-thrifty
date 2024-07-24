# Detect & correct VPC NAT gateways if unused

## Overview

NAT gateways are charged per hour once they are provisioned and available, so unused gateways should be deleted to prevent costs.

This query trigger detects unused NAT gateways and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `vpc_nat_gateways_if_unused_trigger_enabled` should be set to `true` as the default is `false`.
- `vpc_nat_gateways_if_unused_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `vpc_nat_gateways_if_unused_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"delete"` to delete the resource).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```