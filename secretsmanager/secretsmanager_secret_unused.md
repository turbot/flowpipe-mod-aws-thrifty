# SecretsManager Secret Unused

Thrifty developers ensure their secrets manager's secret is in use. This detection finds secrets manager secrets determined to not be in use.

## Variables

| Variable | Description | Default |
| - | - | - |
| secretsmanager_secret_unused_days | The number of days that determines if a secret is unsed. | 90 |
| secretsmanager_secret_unused_default_response | The default response to use for items detected, if no input is required. | "notify" |
| secretsmanager_secret_unused_responses | The response options available to select from if input is required. | ["skip", "delete"] |