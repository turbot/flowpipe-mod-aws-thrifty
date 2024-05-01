# EBS Volumes without Attachments

Thrifty developers keep a careful eye for unused, out-dated, oversized and/or under-utilized EBS volumes. This detection finds EBS volumes without attachments, which render little usage and are expensive to maintain.

## Variables

| Variable | Description | Default |
| - | - | - |
| ebs_volume_without_attachments_default_response | The default response to use for items detected, if no input is required. | "notify" |
| ebs_volume_without_attachments_responses | The response options available to select from if input is required. | ["skip", "delete"] |