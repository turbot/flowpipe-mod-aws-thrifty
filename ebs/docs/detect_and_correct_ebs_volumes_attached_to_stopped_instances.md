# Detect & correct EBS volumes attached to stopped instances

## Overview

EBS volumes attached to stopped instances still incur costs even though they may not be used; these should be reviewed and either detached from the stopped instance or deleted.

This pipeline detects EBS volumes attached to stopped instances and then either sends a notification or attempts to perform a predefined corrective action.

## Getting Started

This control will work out-of-the-box with some sensible defaults (configurable via [variables](https://flowpipe.io/docs/build/mod-variables)).

You should be able to simply run the following command in your terminal:
```sh
flowpipe pipeline run detect_and_correct_ebs_volumes_attached_to_stopped_instances
```

You should now receive notification messages for the detections in your configured [notifier](https://flowpipe.io/docs/reference/config-files/notifier).

However, you may want to actually perform an action against these resources beyond a simple notification.

### Interactive Decisions

Through the use of an [Input Step](https://flowpipe.io/docs/build/input), you can make a decision on how to handle each detected item.

In order to acheieve this, you will need to have an instance of Flowpipe Server running:
```sh
flowpipe server --mod-location=/path/to/mod
```
or if the current working directory contains the mod, simply:
```sh
flowpipe server
```

You can then run the command below:
```sh
flowpipe pipeline run detect_and_correct_ebs_volumes_attached_to_stopped_instances --host local --arg='approvers=["default"]'
```

This will prompt for an action for each detected resource and then attempt to perform the chosen action upon receipt of input.

You can also decide to bypass asking for decision and just automatically apply the same action against all detections.

### Automatic Actioning

You can automatically apply a specific action without the need for running a Flowpipe Server and asking for a decision by setting the `default_action` parameter:
```sh
flowpipe pipeline run detect_and_correct_ebs_volumes_attached_to_stopped_instances --arg='default_action="detach_volume"'
```

However; if you have configured a non-empty list for your `approvers` variable, you will need to override it as below:
```sh
flowpipe pipeline run detect_and_correct_ebs_volumes_attached_to_stopped_instances --arg='approvers=[]' --arg='default_action="detach_volume"'
```

This will attempt to apply the action to every detected item, if you're happy with this approach you could have this occur mmore frequently by either scheduling the command by yourself or enabling the associated [Query Trigger](https://hub.flowpipe.io/mods/turbot/aws_thrifty/triggers/aws_thrifty.trigger.query.detect_and_correct_ebs_volumes_attached_to_stopped_instances).
