with vols_and_instances as (
  select
    v.volume_id,
    i.instance_id,
    v.region,
    v.account_id,
    v._ctx,
    bool_or(i.instance_state = 'stopped') as has_stopped_instances
  from
    aws_ebs_volume as v
    left join jsonb_array_elements(v.attachments) as va on true
    left join aws_ec2_instance as i on va ->> 'InstanceId' = i.instance_id
  group by
    v.volume_id,
    i.instance_id,
    v.region,
    v.account_id,
    v._ctx
)
select
  concat(volume_id, ' [', region, '/', account_id, ']') as title,
  volume_id,
  region,
  _ctx ->> 'connection_name' as cred
from
  vols_and_instances
where
  has_stopped_instances = true;
