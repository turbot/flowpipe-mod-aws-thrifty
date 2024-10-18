## Overview

Amazon EKS node groups that don't use Graviton processor may result in higher operational costs. This query trigger identifies non-Graviton node groups and either sends notifications or attempts predefined corrective actions.

### Getting Started

By default, this trigger is disabled, but can be configured by [setting the variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables):

- `eks_node_groups_without_graviton_trigger_enabled` should be set to `true` (default is `false`).
- `eks_node_groups_without_graviton_trigger_schedule` should be set according to your desired running [schedule](https://flowpipe.io/docs/flowpipe-hcl/trigger/schedule#more-examples).
- `eks_node_groups_without_graviton_default_action` should be set to `"notify"` or any other desired action (e.g., `"notify"` for notifications or `"delete_node_group"` to delete the node group).

Then starting the server:

```sh
flowpipe server
```

or if you've set the variables in a `.fpvars` file:

```sh
flowpipe server --var-file=/path/to/your.fpvars
```
