## Overview

Route53 health checks have an associated monthly cost, therefore those which are no longer required should be removed to prevent further charges.

This query trigger detects unused health checks and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `route53_health_checks_if_unused_trigger_enabled` should be set to `true` as the default is `false`.
- `route53_health_checks_if_unused_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `route53_health_checks_if_unused_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"delete_health_check"` to delete the health check).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```