variable "name" {
  description = "IAM role name (e.g., DataEngineerRole)."
  type        = string
}

variable "description" {
  description = "Human-readable description of what the role is for."
  type        = string
  default     = ""
}

variable "trusted_service" {
  description = "AWS service principal allowed to assume this role (e.g., glue.amazonaws.com)."
  type        = string
}

variable "managed_policy_arns" {
  description = "List of AWS-managed policy ARNs to attach."
  type        = list(string)
  default     = []
}

variable "custom_policy_arns" {
  description = "List of customer-managed policy ARNs to attach."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the role."
  type        = map(string)
  default     = {}
}
