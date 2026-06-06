variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "enable_lifecycle" {
  description = "Enable lifecycle rules (IA after 30d, Glacier after 90d, delete after 365d)"
  type        = bool
  default     = false
}

variable "trusted_role_arns" {
  description = "Optional list of IAM ARNs allowed to assume the S3 roles (cross-account)"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}