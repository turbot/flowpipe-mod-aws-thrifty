# AWS Thrifty Mod for Flowpipe

Pipelines to detect and correct misconfigurations leading to AWS savings opportunities.

## Documentation

- **[Pipelines →](https://hub.flowpipe.io/mods/turbot/aws-thrifty/pipelines)**

## Getting Started

### Requirements

Docker daemon must be installed and running. Please see [Install Docker Engine](https://docs.docker.com/engine/install/) for more information.

### Installation

Download and install Flowpipe (https://flowpipe.io/downloads) and Steampipe (https://steampipe.io/downloads). Or use Brew:

```sh
brew install turbot/tap/flowpipe
brew install turbot/tap/steampipe
```

Install the AWS plugin with [Steampipe](https://steampipe.io):

```sh
steampipe plugin install aws
```

Steampipe will automatically use your default AWS credentials. Optionally, you can [setup multiple accounts](https://hub.steampipe.io/plugins/turbot/aws#multi-account-connections) or [customize AWS credentials](https://hub.steampipe.io/plugins/turbot/aws#configuring-aws-credentials).

Create a `credential_import` resource to import your Steampipe AWS connections:

```sh
vi ~/.flowpipe/config/aws.fpc
```

```hcl
credential_import "aws" {
  source      = "~/.steampipe/config/aws.spc"
  connections = ["*"]
}
```

For more information on importing credentials, please see [Credential Import](https://flowpipe.io/docs/reference/config-files/credential_import).

For more information on credentials in Flowpipe, please see [Managing Credentials](https://flowpipe.io/docs/run/credentials).

Clone the mod:

```sh
mkdir aws-thrifty
cd aws-thrifty
git clone git@github.com:turbot/flowpipe-mod-aws-thrifty.git
```

Install the dependencies:

```sh
flowpipe mod install
```

### Configure Variables

Several pipelines have [input variables](https://flowpipe.io/docs/build/mod-variables#input-variables) that can be configured to better match your environment and requirements.

Each variable has a default defined in its source file, e.g, `s3/s3_buckets_without_lifecycle_policy.fp` (or `variables.fp` for more generic variables), but these can be overwritten in several ways:

The easiest approach is to setup your vars file, starting with the sample:

```sh
cp thrifty.fpvars.example thrifty.fpvars
vi thrifty.fpvars

flowpipe pipeline run detect_and_correct_ebs_snapshots_exceeding_max_age --var-file=thrifty.fpvars
```

Alternatively, you can pass variables on the command line:

```sh
flowpipe pipeline run detect_and_correct_ebs_snapshots_exceeding_max_age --var=ebs_snapshot_age_max_days=10
```

Or through environment variables:

```sh
export FP_VAR_ebs_snapshot_age_max_days=10
flowpipe pipeline run detect_and_correct_ebs_snapshots_exceeding_max_age
```

For more information, please see [Passing Input Variables](https://flowpipe.io/docs/build/mod-variables#passing-input-variables)

### Running Detect and Correct Pipelines

To run your first detection, you'll need to ensure your Steampipe server is up and running:

```sh
steampipe service start
```

To find your desired detection, you can filter the `pipeline list` output:

```sh
flowpipe pipeline list | grep "detect_and_correct"
```

Then run your chosen pipeline:

```sh
flowpipe pipeline run detect_and_correct_ebs_snapshots_exceeding_max_age
```

By default the above approach would find the relevant resources and then send a message to your configured [notifier](https://flowpipe.io/docs/reference/config-files/notifier).

However;  you can request via an [Input Step](https://flowpipe.io/docs/build/input) a corrective action to run against each detection result; this behavior is achieved by setting `approvers` either as a variable or for a one-off approach, by passing `approvers` as an argument.

> Note: This approach requires running `flowpipe server` as it uses an `input` step.

```sh
flowpipe pipeline run detect_and_correct_ebs_snapshots_exceeding_max_age --host local --arg='approvers=["default"]'
```

If you're happy to just apply the same action against all detected items, you can apply them without the `input` step by overriding the `default_action` argument (or the detection specific variable).

```sh
flowpipe pipeline run detect_and_correct_ebs_snapshots_exceeding_max_age --arg='default_action="delete_snapshot"'
```

However; if you have configured a non-empty list for your `approvers` variable, you will need to override it as below:

```sh
flowpipe pipeline run detect_and_correct_ebs_snapshots_exceeding_max_age --arg='approvers=[]' --arg='default_action="delete_snapshot"'
```

Finally, each detection pipeline has a corresponding [Query Trigger](https://flowpipe.io/docs/flowpipe-hcl/trigger/query), these are disabled by default allowing for you to configure only those which are required, see the [docs](https://hub.flowpipe.io/mods/turbot/aws-thrifty/triggers) for more information.

## Open Source & Contributing

This repository is published under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0). Please see our [code of conduct](https://github.com/turbot/.github/blob/main/CODE_OF_CONDUCT.md). We look forward to collaborating with you!

[Flowpipe](https://flowpipe.io) and [Steampipe](https://steampipe.io) are products produced from this open source software, exclusively by [Turbot HQ, Inc](https://turbot.com). They are distributed under our commercial terms. Others are allowed to make their own distribution of the software, but cannot use any of the Turbot trademarks, cloud services, etc. You can learn more in our [Open Source FAQ](https://turbot.com/open-source).

## Get Involved

**[Join #flowpipe on Slack →](https://turbot.com/community/join)**

Want to help but don't know where to start? Pick up one of the `help wanted` issues:

- [Flowpipe](https://github.com/turbot/flowpipe/labels/help%20wanted)
- [AWS Thrifty Mod](https://github.com/turbot/flowpipe-mod-aws-thrifty/labels/help%20wanted)
