# Detect & correct VPC EIPs if unattached

## Overview

Elastic IP addresses are a costly resource to maintain, if they are unattached you will be accruing costs without any benefit; therefore unattached Elastic IP addresses should be released if not required.

This query trigger detects unattached Elastic IP addresses and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `vpc_eips_if_unattached_trigger_enabled` should be set to `true` as the default is `false`.
- `vpc_eips_if_unattached_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `vpc_eips_if_unattached_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"release"` to release the Elastic IP address).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```
<!-- TODO: Determine if we need to elaborate on the flowpipe.db caching difference vs pipeline approach -->