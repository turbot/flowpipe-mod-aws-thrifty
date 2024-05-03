select
  concat(nat.nat_gateway_id, ' [', nat.region, '/', nat.account_id, ']') as title,
  nat.nat_gateway_id,
  nat.region,
  nat._ctx ->> 'connection_name' as cred
from
  aws_vpc_nat_gateway as nat
left join
  aws_vpc_nat_gateway_metric_bytes_out_to_destination as dest
on
  nat.nat_gateway_id = dest.nat_gateway_id
where
  nat.state = 'available'
group by
  nat.nat_gateway_id,
  nat.region,
  nat.account_id,
  nat._ctx ->> 'connection_name'
having
  sum(coalesce(dest.average, 0)) = 0;
