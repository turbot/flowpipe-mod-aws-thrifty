select
  concat(allocation_id, ' [', region, '/', account_id, ']') as title,
  allocation_id,
  region,
  _ctx ->> 'connection_name' as cred
from
  aws_vpc_eip
where
  association_id is null;