# Detect & correct Route53 records with lower TTL

## Overview

Route53 records with a lower TTL result in more DNS queries being received and answered than those with a higher TTL, which in turn results in more costs - common approaches for a TTL are between 3600s (one hour) and 86,400s (one day).

This query trigger detects records with a lower TTL and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `route53_records_with_lower_ttl_trigger_enabled` should be set to `true` as the default is `false`.
- `route53_records_with_lower_ttl_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `route53_records_with_lower_ttl_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"update_ttl"` to update the TTL).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```