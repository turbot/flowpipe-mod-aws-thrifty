# Detect & correct EMR clusters idle for more than 30 mins

EMR clusters which are live but not currently running tasks should be reviewed and checked whether the cluster has been idle for more than 30 minutes. It is ideal to delete such clusters for cost optimization.

This query trigger identifies EMR clusters idle for more than 30 mins and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, but it can be configured by [setting the following variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables):
- `emr_clusters_idle_30_mins_trigger_enabled` should be set to `true` as the default is `false`.
- `emr_clusters_idle_30_mins_trigger_schedule` should be set to your preferred [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples).
- `emr_clusters_idle_30_mins_default_action` should be set to the desired action (e.g., `"notify"` for notifications or `"delete_cluster"` to delete the function).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```