SELECT
    instance_id,
    public_ip_address
FROM
    YOUR-ACCOUNT.aws_ec2_instance
WHERE
    public_ip_address IS NOT NULL;
