select
  concat(volume_id, ' [', volume_type, '/', region, '/', account_id, '/', availability_zone, ']') as title,
  volume_id,
  region,
  _ctx ->> 'connection_name' as cred
from
  aws_ebs_volume
where
  volume_type = 'io1';