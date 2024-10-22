## v1.0.0 (2024-10-22)

_Breaking changes_

- Flowpipe v1.0.0 is now required. For a full list of CLI changes, please see the [Flowpipe v1.0.0 CHANGELOG](https://flowpipe.io/changelog/flowpipe-cli-v1-0-0).
- In Flowpipe configuration files (`.fpc`), `credential` and `credential_import` resources have been renamed to `connection` and `connection_import` respectively.
- Updated the following param types:
  - `approvers`: `list(string)` to `list(notifier)`.
  - `database`: `string` to `connection.steampipe`.
  - `notifier`: `string` to `notifier`.
- Updated the following variable types:
  - `approvers`: `list(string)` to `list(notifier)`.
  - `database`: `string` to `connection.steampipe`.
  - `notifier`: `string` to `notifier`.
- Renamed `cred` param to `conn` and updated its type from `string` to `conn`.

_Enhancements_

- Added `standard` to the mod's categories.
- Updated the following pipeline tags:
  - `type = "featured"` to `recommended = "true"`
  - `type = "test"` to `folder = "Tests"`
- Added the `folder = "Internal"` tag to pipelines that are not meant to be run directly.
- Added the `folder = "Advanced/<service>"` tag to variables.
- Added `enum` to `*_default_action`, `*_enabled_actions`, and `*_notification_level` params and variables.
- Added `format` to params and variables that use multiline and JSON strings.

## v0.3.0 [2024-07-24]

_What's new?_

- The mod has been updated to run in the [Wizard mode](https://hub.flowpipe.io/mods/turbot/aws_thrifty#wizard) by default.

## v0.2.0 [2024-05-17]

_What's new?_

- Added `Detect and Correct` pipeline for DynamoDB tables with stale data. ([#34](https://github.com/turbot/flowpipe-mod-aws-thrifty/pull/34))

## v0.1.0 [2024-05-13]

_What's new?_

- Added 30 new 'detect and correct' pipelines to identify unused and underutilized AWS resources, as well as deprecated resource configurations. These pipelines also suggest potential remediation actions to optimize costs. For usage information and a full list of pipelines, please see [AWS Thrifty Mod](https://hub.flowpipe.io/mods/turbot/aws_thrifty).
