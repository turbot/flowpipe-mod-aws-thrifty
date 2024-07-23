# Detect & correct EC2 instances without graviton processor

EC2 instances without graviton processor incur cost over time, with graviton processor (arm64 - 64-bit ARM architecture), you can save money in two ways: First, your instances run more efficiently due to the Graviton architecture. Second, you pay less for the time that they run. In fact, EC2 instances powered by Graviton are designed to deliver up to 19 percent better performance at 20 percent lower cost.

This query trigger identifies EC2 instances without graviton processor and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, but it can be configured by [setting the following variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables):
- `ec2_instances_without_graviton_trigger_enabled` should be set to `true` as the default is `false`.
- `ec2_instances_without_graviton_trigger_schedule` should be set to your preferred [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples).
- `ec2_instances_without_graviton_default_action` should be set to the desired action (e.g., `"notify"` for notifications or `"terminate_instance"` to delete the instance).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```