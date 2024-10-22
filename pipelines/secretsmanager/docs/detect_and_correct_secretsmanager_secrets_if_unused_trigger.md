## Overview

SecretsManager secrets have an inherent monthly cost, therefore secrets which are no longer accessed / used should be removed to prevent further charges.

This query trigger detects unused secrets and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, however it can be configured by [setting the below variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)
- `secretsmanager_secrets_if_unused_trigger_enabled` should be set to `true` as the default is `false`.
- `secretsmanager_secrets_if_unused_trigger_schedule` should be set to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples)
- `secretsmanager_secrets_if_unused_default_action` should be set to your desired action (i.e. `"notify"` for notifications or `"delete_secret"` to delete the secret).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```