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

+-------------------+-------------+--------------------+--------+------------+
| target_group_name | target_type | load_balancer_arns | vpc_id | account_id |
+-------------------+-------------+--------------------+--------+------------+
+-------------------+-------------+--------------------+--------+------------+
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

+-----------------------------------------------------------------------+------------+
| name                                                                  | type       |
+-----------------------------------------------------------------------+------------+
+------------------------------------------------------------------------------------+
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

