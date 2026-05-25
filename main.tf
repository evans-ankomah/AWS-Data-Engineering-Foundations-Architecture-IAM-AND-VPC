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

  tags = var.tags
}
