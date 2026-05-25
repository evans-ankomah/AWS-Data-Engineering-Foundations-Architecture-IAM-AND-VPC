# Terraform — Data Engineering IAM

Terraform implementation of the IAM stack described in
[IAM Setup for Data Engineering.md](IAM%20Setup%20for%20Data%20Engineering.md).

Creates 5 IAM roles and 1 customer-managed policy with encryption
enforcement for a `data-lake-*` S3 namespace.

## What gets created

| Resource | Type | Trust / Notes |
|---|---|---|
| `DataEngineerRole` | IAM role | EC2 service principal — S3, Glue, Redshift, EMR, Kinesis, Lambda, CloudWatch |
| `GlueServiceRole` | IAM role | Glue service principal — S3, CloudWatch, Secrets Manager |
| `LambdaExecutionRole` | IAM role | Lambda service principal — S3, DynamoDB, Kinesis, Secrets Manager |
| `RedshiftIAMRole` | IAM role | Redshift service principal — S3, CloudWatch |
| `AnalystReadOnlyRole` | IAM role | EC2 service principal — Athena, Redshift, QuickSight, S3 (all read-only) |
| `DataLakeBucketAccessPolicy` | IAM policy | Allows access to `arn:aws:s3:::data-lake-*`; **denies** any `s3:PutObject` without `x-amz-server-side-encryption=AES256` |

The custom policy is attached to the three data-plane roles only
(`DataEngineerRole`, `GlueServiceRole`, `LambdaExecutionRole`). The
explicit `Deny` overrides the broader `Allow` from `AmazonS3FullAccess`
on those roles, so unencrypted uploads to the data lake are blocked.

## Layout

```
terraform_with_AWS/
├── main.tf                  # provider + 5 module calls + custom policy
├── variables.tf             # aws_region, tags
├── outputs.tf               # role ARNs + custom policy ARN
├── terraform.tfvars.example
└── modules/
    └── iam_role/            # reusable: role + assume-role + attachments
```

## Prerequisites

- Terraform `>= 1.5`
- AWS credentials configured (`aws configure`, `AWS_PROFILE`, or
  `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` env vars)
- IAM permissions to create roles, policies, and policy attachments

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars   # edit values
terraform init
terraform plan
terraform apply
```

Expected plan summary: **5 roles + 1 policy + 25 policy attachments**
(22 AWS-managed + 3 customer-managed).

## Verify (maps to lab PART 6)

Console — IAM → Roles:

- All 5 role names present.
- `DataEngineerRole` → Permissions tab: 7 managed policies **plus**
  `DataLakeBucketAccessPolicy`.
- `AnalystReadOnlyRole` → only the 4 read-only policies.

CLI — get the ARNs straight from Terraform:

```bash
terraform output
```

Optional encryption-deny test (requires an existing `data-lake-*`
bucket and the ability to assume `DataEngineerRole`):

```bash
aws s3 cp file.txt s3://data-lake-test/foo                  # expect AccessDenied
aws s3 cp file.txt s3://data-lake-test/foo --sse AES256     # expect success
```

## Cleanup

IAM roles and policies are free. Destroy only when you no longer need
the lab:

```bash
terraform destroy
```

## Notes on managed policy names

A few lab names differ from the current AWS-published policy names; the
ARNs in `main.tf` use the AWS-current names and call out the lab name
inline:

- `AWSGlueFullAccess` → `AWSGlueConsoleFullAccess`
- `AWSLambdaFullAccess` → `AWSLambda_FullAccess`
- `AmazonEMRFullAccessPolicy_v2` lives under `service-role/` in its ARN
- `AmazonQuickSightReadOnlyAccess` is deprecated by AWS in favor of
  QuickSight-native group management; still attached as the lab requests
