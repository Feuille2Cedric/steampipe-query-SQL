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