## Overview

Elastic IP addresses are a costly resource to maintain, if they are unattached you will be accruing costs without any benefit; therefore unattached Elastic IP addresses should be released if not required.

This control aims to allow you to detect unattached Elastic IP addresses and then send a notification, attempt a corrective action or ignore it.

There are 3 related pipelines in order to allow you to determine the entrypoint which suits your workflow:
- `detect_and_correct_vpc_eips_unattached`: Utilises a Steampipe connection/query to obtain a dataset of unattached Elastic IP addresses, which are then passed to the pipeline `correct_vpc_eips_unattached`
- `correct_vpc_eips_unattached`: Accepts a collection of unattached Elastic IP addresses, if `notification_level` is `"verbose"` will send a message containing a count of these before iterating each result into the next pipeline `correct_one_vpc_eip_unattached`.
- `correct_one_vpc_eip_unattached`: Accepts a single unattached Elastic IP address and will attempt to perform an action based on the configured **running mode**.

In addition, you can utilise a more hands-off approach by enabling the [Query Trigger](https://flowpipe.io/docs/flowpipe-hcl/trigger/query), this will need to be done by specifying the following [variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables) when starting the `flowpipe server`:
- `vpc_eips_unattached_trigger_enabled` - set to `true` to enable, `false` to disable.
- `vpc_eips_unattached_trigger_schedule` - should be set to the desired [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples).

## Running Modes
There are 3 modes in which these `detect & correct` pipelines can be run:
- **Notification Only**: sends a message for each detected item to the specified [notifier](https://flowpipe.io/docs/reference/config-files/notifier).
- **Wizard**: sends a request to determine an action to the specified `approvers`, will then proceed to attempt this action.
- **Automatic Action**: attempts to automatically apply the configured `default_action`.

### Notifications Only

This is the **default** configuration, to configure this mode you will need to set the below parameters.
- `approvers` should be set to an empty list `[]`. 
- `default_action` should be set to `"notify"`.

### Wizard

This approach can be used to ascertain a specific correction for each **detected item**, to enable this running mode - you will need to set the below parameters.
- `approvers` should be set to contain configured notifiers to use for sending the requests, for example: `["devops"]`.
- `enabled_actions` should be set to the action options you wish to provide for selection as a string array, valid actions are:
  - `"skip"` - this will ignore the detection, although you will get a notification message if `notification_level` variable is set to `"verbose"`.
  - `"release"` - this will attempt to release the elastic IP, information on success/failure of this action will be sent to the notifier configured in the `notifier` variable.

### Automatic Action

This mode is used to attempt to apply a default action against all **detected items**.

To configure this approach, you will beed to configure the below variables:
- `approvers` should be set to an empty list `[]`.
- `default_action` should be set to one of the following:
  - `"skip"` - this will ignore the detection, although you will get a notification message if `notification_level` variable is set to `"verbose"`.
  - `"release"` - this will attempt to release the elastic IP, information on success/failure of this action will be sent to the notifier configured in the `notifier` variable.

## Variable Configuration

To reduce the number of parameters you are required to pass, you can instead containue to use the default value of the parameter - and provide [variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables) instead.

- **Mod Variables** can be found in the [variables.fp](https://github.com/turbot/flowpipe-mod-aws-thrifty/blob/init/variables.fp) file.
- **vpc_eips_unattached Variables** can be found in the [vpc_eips_unattached.fp](https://github.com/turbot/flowpipe-mod-aws-thrifty/blob/init/vpc/vpc_eips_unattached.fp) file.
<!-- TODO: Update links above to correct path when code is on main branch -->