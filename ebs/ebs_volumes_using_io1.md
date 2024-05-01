# EBS Volumes using IO1

Thrifty developers keep a careful eye for unused, out-dated, oversized and/or under-utilized EBS volumes. This detection finds volumes using IO1, which are less reliable for the same cost as IO2.

## Variables

| Variable | Description | Default |
| - | - | - |
| ebs_volume_using_io1_default_response | The default response to use for items detected, if no input is required. | "notify" |
| ebs_volume_using_io1_responses | The response options available to select from if input is required. | ["skip", "update"] |