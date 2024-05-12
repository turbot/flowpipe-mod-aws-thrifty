# Detect & correct Lambda functions without graviton processor

Lambda functions without graviton processor incur cost over time, with graviton processor (arm64 - 64-bit ARM architecture), you can save money in two ways: First, your functions run more efficiently due to the Graviton architecture. Second, you pay less for the time that they run. In fact, Lambda functions powered by Graviton are designed to deliver up to 19 percent better performance at 20 percent lower cost.

This query trigger identifies Lambda functions without graviton processor and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, but it can be configured by [setting the following variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables):
- `lambda_functions_without_graviton_trigger_enabled` should be set to `true` as the default is `false`.
- `lambda_functions_without_graviton_trigger_schedule` should be set to your preferred [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples).
- `lambda_functions_without_graviton_default_action` should be set to the desired action (e.g., `"notify"` for notifications or `"delete_cluster"` to delete the function).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```