# AWS Thrifty Mod for Flowpipe

Pipelines to detect & correct misconfigurations leading to AWS savings opportunities.

## Getting Started

### Installation

Install [Flowpipe](https://flowpipe.io/downloads), or use Brew:

```sh
brew install turbot/tap/flowpipe
```

This mod also requires [Steampipe](https://steampipe.io) with the [AWS plugin](https://hub.steampipe.io/plugins/turbot/aws) as the data source. 

Install [Steampipe](https://steampipe.io/downloads), or use Brew:

```sh
brew install turbot/tap/steampipe
steampipe plugin install aws
```

Steampipe will automatically use your default AWS credentials. Optionally, you can [setup multiple accounts](https://hub.steampipe.io/plugins/turbot/aws#multi-account-connections) or [customize AWS credentials](https://hub.steampipe.io/plugins/turbot/aws#configuring-aws-credentials).

Finally, install the mod:

```sh
flowpipe mod init
flowpipe mod install github.com/turbot/flowpipe-mod-aws-thrifty
```

### Configure Variables

Several pipelines have [input variables](https://flowpipe.io/docs/build/mod-variables#input-variables) that can be configured to better match your environment and requirements.

Each variable has a default defined in it's source file, e.g, `s3/s3.fp` (or `variables.fp` for more generic variables), but these can be overwritten in several ways:

The easiest approach is to setup your vars file, starting with the sample:

```sh
cp thrifty.fpvars.example thrifty.fpvars
vi thrifty.fpvars
```

Alternatively you can pass variables on the command line:

```sh
flowpipe pipeline run detect_and_correct_ebs_snapshots_exceeding_max_age --var=ebs_snapshot_age_max_days=10
```

Or through environment variables:

```sh
export FP_VAR_ebs_snapshot_age_max_days=10
flowpipe pipeline run detect_and_correct_ebs_snapshots_exceeding_max_age
```

For more information, please see [Passing Input Variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)

### Running Your First Detection

Once you've configured your variables, you can get started by simply running one of the available pipelines:

```sh
flowpipe pipeline run detect_and_correct_ebs_snapshots_exceeding_max_age
```

Each detection has a corresponding [Query Trigger](https://flowpipe.io/docs/flowpipe-hcl/trigger/query), by default - these are `Disabled` so that you can customize which you wish to enable and the frequency of their running. <!-- TODO: Get link to .fptriggers docs once available -->


<!-- TODO: Mention how to obtain human input - link out for setup/instructions/tutorials -->

## Open Source & Contributing

This repository is published under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0). Please see our [code of conduct](https://github.com/turbot/.github/blob/main/CODE_OF_CONDUCT.md). We look forward to collaborating with you!

[Flowpipe](https://flowpipe.io) and [Steampipe](https://steampipe.io) are products produced from this open source software, exclusively by [Turbot HQ, Inc](https://turbot.com). They are distributed under our commercial terms. Others are allowed to make their own distribution of the software, but cannot use any of the Turbot trademarks, cloud services, etc. You can learn more in our [Open Source FAQ](https://turbot.com/open-source).

## Get Involved

**[Join #flowpipe on Slack →](https://turbot.com/community/join)**

Want to help but don't know where to start? Pick up one of the `help wanted` issues:

- [Flowpipe](https://github.com/turbot/flowpipe/labels/help%20wanted)
- [AWS Thrifty Mod](https://github.com/turbot/flowpipe-mod-aws-thrifty/labels/help%20wanted)