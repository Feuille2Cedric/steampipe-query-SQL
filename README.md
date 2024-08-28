# steampipe-query-SQL
Command and documentation about Steampipe query

## Target group without lb in target by account_id 

```sql
SELECT
  target_group_name,
  target_type,
  load_balancer_arns,
  vpc_id,
  account_id
FROM
  YOUR-ACCOUNT.aws_ec2_target_group
WHERE
  load_balancer_arns = '[]'
AND account_id = 'YOUR-ID';
```

## SSM Parameter without Encryption

```sql
SELECT 
  name,
  type,
  value
FROM 
  YOUR-ACCOUNT.aws_ssm_parameter
WHERE
  type = 'String'
OR
  type = 'StringList'
```

## AWS AMI Encryption

```sql
SELECT
    name,
    image_id,
    block_device_mappings
FROM
    YOUR-ACCOUNT.aws_ec2_ami
WHERE
    EXISTS (
        SELECT 1
        FROM jsonb_array_elements(block_device_mappings) AS elem
        WHERE elem -> 'Ebs' ->> 'Encrypted' = 'false'
    );
```

## EBS Snapshot Encrypted

```sql
SELECT
    snapshot_id,
    volume_id,
    encrypted,
    account_id
FROM
    YOUR-ACCOUNT.aws_ebs_snapshot
WHERE
    encrypted = 'False'
```

## EC2 Instance Not In Public Subnet

```sql
SELECT
    instance_id,
    public_ip_address
FROM
    YOUR-ACCOUNT.aws_ec2_instance
WHERE
    public_ip_address IS NOT NULL;

```
