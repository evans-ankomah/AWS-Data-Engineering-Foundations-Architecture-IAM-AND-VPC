terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# Role 1: DataEngineerRole
# Main role used by data engineers for day-to-day pipeline work across
# S3, Glue, Redshift, EMR, Kinesis, Lambda, and CloudWatch.
module "data_engineer_role" {
  source = "./modules/iam_role"

  name            = "DataEngineerRole"
  description     = "Data engineer role: S3, Glue, Redshift, EMR, Kinesis, Lambda, CloudWatch."
  trusted_service = "ec2.amazonaws.com"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",                 # lab name: AWSGlueFullAccess
    "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess",
    "arn:aws:iam::aws:policy/service-role/AmazonEMRFullAccessPolicy_v2",
    "arn:aws:iam::aws:policy/AmazonKinesisFullAccess",
    "arn:aws:iam::aws:policy/AWSLambda_FullAccess",                     # lab name: AWSLambdaFullAccess (renamed by AWS)
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
  ]

  custom_policy_arns = [aws_iam_policy.data_lake_bucket_access.arn]

  tags = var.tags
}

# Role 2: GlueServiceRole
# Assumed by AWS Glue jobs to read/write S3, log to CloudWatch, and
# fetch connection credentials from Secrets Manager.
module "glue_service_role" {
  source = "./modules/iam_role"

  name            = "GlueServiceRole"
  description     = "Service role for AWS Glue ETL jobs (S3, CloudWatch, Secrets Manager)."
  trusted_service = "glue.amazonaws.com"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  ]

  custom_policy_arns = [aws_iam_policy.data_lake_bucket_access.arn]

  tags = var.tags
}

# Role 3: LambdaExecutionRole
# Execution role for Lambda functions doing serverless data processing
# against S3, DynamoDB, Kinesis, and Secrets Manager.
module "lambda_execution_role" {
  source = "./modules/iam_role"

  name            = "LambdaExecutionRole"
  description     = "Execution role for Lambda data-processing functions."
  trusted_service = "lambda.amazonaws.com"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonKinesisFullAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  ]

  custom_policy_arns = [aws_iam_policy.data_lake_bucket_access.arn]

  tags = var.tags
}

# Role 4: RedshiftIAMRole
# Attached to Redshift clusters so COPY/UNLOAD commands can read from
# and write to S3, and so the cluster can log to CloudWatch.
module "redshift_iam_role" {
  source = "./modules/iam_role"

  name            = "RedshiftIAMRole"
  description     = "Role assumed by Redshift for S3 COPY/UNLOAD and CloudWatch logging."
  trusted_service = "redshift.amazonaws.com"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
  ]

  tags = var.tags
}

# Role 5: AnalystReadOnlyRole
# Read-only role for analysts running queries in Athena/Redshift and
# building dashboards in QuickSight.
module "analyst_read_only_role" {
  source = "./modules/iam_role"

  name            = "AnalystReadOnlyRole"
  description     = "Read-only access for analysts: Athena, Redshift, QuickSight, S3."
  trusted_service = "ec2.amazonaws.com"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonAthenaFullAccess",
    "arn:aws:iam::aws:policy/AmazonRedshiftReadOnlyAccess",
    # NOTE: AmazonQuickSightReadOnlyAccess is deprecated; AWS recommends
    # managing QuickSight access via QuickSight's own group/role system.
    "arn:aws:iam::aws:policy/AmazonQuickSightReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
  ]

  tags = var.tags
}

# Custom policy: DataLakeBucketAccessPolicy
# Scopes access to data-lake-* buckets and enforces SSE-S3 (AES256)
# encryption on uploads. The explicit Deny on unencrypted PutObject
# overrides the broader Allow from AmazonS3FullAccess on attached roles.
resource "aws_iam_policy" "data_lake_bucket_access" {
  name        = "DataLakeBucketAccessPolicy"
  description = "Restrict access to data-lake-* buckets and block unencrypted uploads."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListDataLakeBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = "arn:aws:s3:::data-lake-*"
      },
      {
        Sid    = "ReadWriteDataLakeObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = "arn:aws:s3:::data-lake-*/*"
      },
      {
        Sid      = "DenyUnencryptedUploads"
        Effect   = "Deny"
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::data-lake-*/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
    ]
  })

  tags = var.tags
}
