# EBS Volumes using GP2

Thrifty developers keep a careful eye for unused, out-dated, oversized and/or under-utilized EBS volumes. This detection finds volumes using GP2, which is more costly and lower performance than GP3.

## Variables

| Variable | Description | Default |
| - | - | - |
| ebs_volume_using_gp2_default_response | The default response to use for items detected, if no input is required. | "notify" |
| ebs_volume_using_gp2_responses | The response options available to select from if input is required. | ["skip", "update"] |