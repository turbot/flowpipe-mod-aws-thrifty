select
  concat(volume_id, ' [', region, '/', account_id, ']') as title,
  volume_id,
  region,
  _ctx ->> 'connection_name' as cred
from
  aws_ebs_volume
where
  jsonb_array_length(attachments) = 0;