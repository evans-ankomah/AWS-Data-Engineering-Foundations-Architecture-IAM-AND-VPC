variable "aws_region" {
  description = "AWS region to deploy IAM and related resources into."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Default tags applied to every taggable resource."
  type        = map(string)
  default = {
    Project   = "DataEngineeringPlatform"
    ManagedBy = "Terraform"
  }
}
