# Detect & correct EC2 application load balancers if unused

Amazon EC2 application load balancers with no targets attached still cost money and should be deleted. This query trigger identifies EC2 application load balancers with no targets attached and either sends notifications or attempts predefined corrective actions.

### Getting Started

By default, this trigger is disabled, but can be configured by [setting the variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables):

- `ec2_application_load_balancers_if_unused_trigger_enabled` should be set to `true` (default is `false`).
- `ec2_application_load_balancers_if_unused_trigger_schedule` should be set according to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples).
- `ec2_application_load_balancers_if_unused_default_action` should be set to `"notify"` or any other desired action (e.g., `"notify"` for notifications or `"delete_load_balancer"` to delete the application load balancers).

Then starting the server:

```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:

```sh
flowpipe server --var-file=/path/to/your.fpvars
```
