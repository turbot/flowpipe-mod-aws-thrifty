# EBS Snapshots Exceeding Max Age

Thrifty developers keep a careful eye for unused, out-dated, oversized and/or under-utilized EBS volumes. This detection finds snapshots which exceed the given max age which are likely unnecessary and costly to maintain.

## Variables

| Variable | Description | Default |
| - | - | - |
| ebs_snapshot_age_max_days | The maximum number of days that EBS snapshots can be retained. | 90 |
| ebs_snapshot_age_max_days_default_response | The default response to use for items detected, if no input is required. | "notify" |
| ebs_snapshot_age_max_days_responses | The response options available to select from if input is required. | ["skip", "delete"] |