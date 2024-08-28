WITH recent_snapshots AS (
  SELECT DISTINCT
    volume_id
  FROM
    teamwork_aws_all.aws_ebs_snapshot
  WHERE
    start_time >= current_date - interval '1 days' -- Replace '30' with the desired number of days
),
volumes_without_recent_snapshots AS (
  SELECT
    volume_id,
    availability_zone,
    state,
    size,
    jsonb_array_elements(attachments::jsonb) ->> 'instance_id' AS instance_id
  FROM
    teamwork_aws_all.aws_ebs_volume
  WHERE
    volume_id NOT IN (SELECT volume_id FROM recent_snapshots)
)
SELECT
  v.volume_id,
  v.availability_zone,
  v.state,
  v.size,
  i.instance_id,
  i.instance_state,
  i.instance_type,
  i.tags ->> 'Name' AS instance_name
FROM
  volumes_without_recent_snapshots v
JOIN
  teamwork_aws_all.aws_ec2_instance i ON v.instance_id = i.instance_id
ORDER BY
  i.account_id;
