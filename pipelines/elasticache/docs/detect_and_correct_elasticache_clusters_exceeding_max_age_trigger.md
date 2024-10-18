## Overview

ElastiCache clusters have an ongoing operational cost, so clusters that surpass a certain age should be retired to prevent unnecessary expenses.

This query trigger identifies ElastiCache clusters exceeding the maximum age and then either sends a notification or attempts to perform a predefined corrective action.

### Getting Started

By default, this trigger is disabled, but it can be configured by [setting the following variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables):
- `elasticache_clusters_exceeding_max_age_trigger_enabled` should be set to `true` as the default is `false`.
- `elasticache_clusters_exceeding_max_age_trigger_schedule` should be set to your preferred [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples).
- `elasticache_clusters_exceeding_max_age_default_action` should be set to the desired action (e.g., `"notify"` for notifications or `"delete_cluster"` to delete the cluster).

Then starting the server:
```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:
```sh
flowpipe server --var-file=/path/to/your.fpvars
```