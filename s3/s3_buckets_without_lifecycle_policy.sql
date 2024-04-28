select
  concat(name, ' [', account_id, ']') as title,
  name,
  region,
  _ctx ->> 'connection_name' as cred
from
  aws_s3_bucket
where
  lifecycle_rules is null;