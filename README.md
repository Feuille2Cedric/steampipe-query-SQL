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

## Lambda Using Unsupported Runtime Environment

```sql
SELECT
    name,
    runtime,
    handler,
    role,
    last_modified
FROM
    YOUR-ACCOUNT.aws_lambda_function
WHERE
    runtime NOT IN ('nodejs18.x', 'nodejs16.x', 'python3.11', 'python3.10', 'python3.9', 'ruby3.2', 'ruby3.1', 
                  'java17', 'java11', 'dotnet7', 'dotnet6', 'go1.x', 'provided.al2');
```

## S3 Cross Account Access

```sql
WITH cross_account_access AS (
    SELECT
        name,
        account_id,
        jsonb_array_elements_text(policy::jsonb -> 'Statement')::jsonb AS statement
    FROM
        YOUR-ACCOUNT.aws_s3_bucket
    WHERE
        policy IS NOT NULL
),
allowed_accounts_scalar AS (
    SELECT
        name,
        account_id,
        statement -> 'Principal' ->> 'AWS' AS allowed_account_id
    FROM
        cross_account_access
    WHERE
        (statement -> 'Principal' -> 'AWS') IS NOT NULL
),
allowed_accounts_array AS (
    SELECT
        name,
        account_id,
        jsonb_array_elements_text(statement -> 'Principal' -> 'AWS') AS allowed_account_id
    FROM
        cross_account_access
    WHERE
        jsonb_typeof(statement -> 'Principal' -> 'AWS') = 'array'
),
all_allowed_accounts AS (
    SELECT * FROM allowed_accounts_scalar
    UNION ALL
    SELECT * FROM allowed_accounts_array
)
SELECT
    name,
    account_id,
    STRING_AGG(allowed_account_id, ', ') AS allowed_accounts
FROM
    all_allowed_accounts
WHERE
    allowed_account_id IS NOT NULL
    AND allowed_account_id LIKE 'arn:aws:iam::%:root'
    AND allowed_account_id NOT LIKE 'arn:aws:iam::' || account_id || ':root'
GROUP BY
    name, account_id
ORDER BY
    account_id;
```

## EBS Volumes Recent Snapshots

```sql
WITH recent_snapshots AS (
  SELECT DISTINCT
    volume_id
  FROM
    YOUR-ACCOUNT.aws_ebs_snapshot
  WHERE
    start_time >= current_date - interval '30 days' -- Adjust the number of days as needed
),
volumes_without_recent_snapshots AS (
  SELECT
    volume_id,
    availability_zone,
    state,
    size,
    jsonb_array_elements(attachments::jsonb) ->> 'instance_id' AS instance_id
  FROM
    YOUR-ACCOUNT.aws_ebs_volume
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
  YOUR-ACCOUNT.aws_ec2_instance i ON v.instance_id = i.instance_id
ORDER BY
  i.account_id;
```

## S3 Buckets Encrypted with Customer-Provided CMKs

```sql
SELECT
  name,
  CASE
    WHEN server_side_encryption_configuration IS NULL THEN 'Not Encrypted'
    WHEN server_side_encryption_configuration::text LIKE '%aws:kms%' AND server_side_encryption_configuration::text LIKE '%arn:aws:kms%' THEN 'Encrypted with CMK'
    WHEN server_side_encryption_configuration::text LIKE '%AES256%' THEN 'Encrypted without CMK'
    ELSE 'Unknown'
  END AS encryption_status,
  server_side_encryption_configuration
FROM
  YOUR-ACCOUNT.aws_s3_bucket;
```

## EC2 Instance Using IAM Roles

```sql
SELECT
  instance_id,
  CASE
    WHEN iam_instance_profile_arn IS NOT NULL THEN 'IAM Role'
    ELSE 'Access Key'
  END AS authentication_method,
  instance_type,
  instance_state AS state,
  iam_instance_profile_arn AS iam_role_arn
FROM
  YOUR-ACCOUNT.aws_ec2_instance;
```

## Unused AWS EC2 Key Pairs

```sql
WITH used_key_pairs AS (
  SELECT
    DISTINCT key_name,
    STRING_AGG(instance_id, ', ') AS instances
  FROM
    YOUR-ACCOUNT.aws_ec2_instance
  WHERE
    key_name IS NOT NULL
  GROUP BY
    key_name
)
SELECT
  kp.key_name,
  CASE
    WHEN ukp.key_name IS NOT NULL THEN 'Used'
    ELSE 'Unused'
  END AS usage_status,
  COALESCE(ukp.instances, 'None') AS instances_used
FROM
  YOUR-ACCOUNT.aws_ec2_key_pair kp
LEFT JOIN
  used_key_pairs ukp ON kp.key_name = ukp.key_name;
```

## EC2 Instance Termination Protection

```sql
SELECT
  instance_id,
  instance_type,
  instance_state AS state,
  CASE
    WHEN disable_api_termination = true THEN 'Enabled'
    ELSE 'Disabled'
  END AS termination_protection_status
FROM
  YOUR-ACCOUNT.aws_ec2_instance;
```

## Password Policy Expiration

```sql
SELECT
  CASE 
    WHEN expire_passwords THEN 'Enabled'
    ELSE 'Disabled'
  END AS password_expiration_status
FROM
  YOUR-ACCOUNT.aws_iam_account_password_policy;
```

## S3 Bucket Versioning Enabled

```sql
SELECT
  name AS bucket_name,
  versioning_enabled
FROM
  YOUR-ACCOUNT.aws_s3_bucket;
```
