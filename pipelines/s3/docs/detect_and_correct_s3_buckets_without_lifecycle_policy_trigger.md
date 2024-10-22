## Overview

S3 Buckets without a lifecycle policy will not move objects between storage layers or expire objects, causing them to remain in their initial tier perpetually, this is inefficient and can be costly.

This query trigger detects S3 buckets which do not have a lifecycle policy attached and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `s3_buckets_without_lifecycle_policy_trigger_enabled` should be set to `true` as the default is `false`.
- `s3_buckets_without_lifecycle_policy_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `s3_buckets_without_lifecycle_policy_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"apply_lifecycle_configuration"` to apply the policy).
- `s3_buckets_without_lifecycle_policy_default_lifecycle_configuration` should be set to your desired lifecycle configuration if `s3_buckets_without_lifecycle_policy_default_action` is set to `"apply_lifecycle_configuration"`.

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```
<!-- TODO: Determine if we need to elaborate on the flowpipe.db caching difference vs pipeline approach -->
