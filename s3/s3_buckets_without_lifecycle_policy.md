# S3 Buckets without lifecycle policy

Thrifty developers ensure their S3 buckets have managed lifecycle policies, this detection finds buckets without a lifecycle policy and performs your chosen reponse.

| Variable | Description | Default |
| - | - | - |
| s3_bucket_default_lifecycle_policy | The lifecycle policy to be applied with the `apply` reponse. | {"Rules":[{"ID":"Expire all objects after one year","Status":"Enabled","Expiration":{"Days":365}}]} |
| s3_bucket_without_lifecycle_policy_default_response | The default response to use for items detected, if no input is required. | "notify" |
| s3_bucket_without_lifecycle_policy_responses | The response options available to select from if input is required. | ["skip", "apply"] |