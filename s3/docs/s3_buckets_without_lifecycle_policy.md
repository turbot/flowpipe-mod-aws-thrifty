## Overview

S3 Buckets without a lifecycle policy will not move objects between storage layers or expire objects, causing them to remain in their initial tier perpetually, this is inefficient and can be costly.

This control aims to allow you to detect S3 buckets which do not have a life cycle policy attached and then send a notification, attempt a corrective action or ignore it.
<!-- YANK THIS-->
There are 3 related pipelines in order to allow you to determine the entrypoint which suits your workflow:
- `detect_and_correct_s3_buckets_without_lifecycle_policy`: Utilises a Steampipe connection/query to obtain a dataset of S3 buckets without an attached lifecycle policy, which are then passed to the pipeline `correct_s3_buckets_without_lifecycle_policy`
- `correct_s3_buckets_without_lifecycle_policy`: Accepts a collection of S3 buckets, if `notification_level` is `"verbose"` will send a message containing a count of these before iterating each result into the next pipeline `correct_one_s3_bucket_without_lifecycle_policy`.
- `correct_one_s3_bucket_without_lifecycle_policy`: Accepts a single S3 bucket and will attempt to perform an action based on the configured **running mode**.

In addition, you can utilise a more hands-off approach by enabling the [Query Trigger](https://flowpipe.io/docs/flowpipe-hcl/trigger/query), this will need to be done by specifying the following [variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables) when starting the `flowpipe server`:
- `s3_buckets_without_lifecycle_policy_trigger_enabled` - set to `true` to enable, `false` to disable.
- `s3_buckets_without_lifecycle_policy_trigger_schedule` - should be set to the desired [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples).
<!-- Swap Running Modes for Tutorial "how to use" / learn by doing! -->
## Running Modes
There are 3 modes in which these `detect & correct` pipelines can be run:
- **Notification Only**: sends a message for each detected item to the specified [notifier](https://flowpipe.io/docs/reference/config-files/notifier).
- **Wizard**: sends a request to determine an action to the specified `approvers`, will then proceed to attempt this action.
- **Automatic Action**: attempts to automatically apply the configured `default_action`.

### Notify

This is the **default** configuration, to configure this mode you will need to set the below parameters.
- `approvers` should be set to an empty list `[]`. 
- `default_action` should be set to `"notify"`.

### Interactive

This approach can be used to ascertain a specific correction for each **detected item**, to enable this running mode - you will need to set the below parameters.
- `approvers` should be set to contain configured notifiers to use for sending the requests, for example: `["devops"]`.
- `enabled_actions` should be set to the action options you wish to provide for selection as a string array, valid actions are:
  - `"skip"` - this will ignore the detection, although you will get a notification message if `notification_level` variable is set to `"verbose"`.
  - `"apply_policy"` - this will attempt to apply the policy defined in the variable `s3_buckets_without_lifecycle_policy_default_policy`, information on success/failure of this action will be sent to the notifier configured in the `notifier` variable.

### Automatic

This mode is used to attempt to apply a default action against all **detected items**.

To configure this approach, you will beed to configure the below variables:
- `approvers` should be set to an empty list `[]`.
- `default_action` should be set to one of the following:
  - `"skip"` - this will ignore the detection, although you will get a notification message if `notification_level` variable is set to `"verbose"`.
  - `"apply_policy"` - this will attempt to apply the policy defined in the variable `s3_buckets_without_lifecycle_policy_default_policy`, information on success/failure of this action will be sent to the notifier configured in the `notifier` variable.

## Variable Configuration

The following variables should be reviewed and if necessary amended **BEFORE** running this `Detect & Correct` flow:
- `s3_buckets_without_lifecycle_policy_default_policy`: Contains a lifecycle policy that will be applied to S3 buckets if `apply_policy`.

To reduce the number of parameters you are required to pass, you can instead containue to use the default value of the parameter - and provide [variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables) instead.

- **Mod Variables** can be found in the [variables.fp](https://github.com/turbot/flowpipe-mod-aws-thrifty/blob/init/variables.fp) file.
- **s3_buckets_without_lifecycle_policy Variables** can be found in the [s3_buckets_without_lifecycle_policy.fp](https://github.com/turbot/flowpipe-mod-aws-thrifty/blob/init/s3/s3_buckets_without_lifecycle_policy.fp) file.
<!-- TODO: Update links above to correct path when code is on main branch -->