aws_region        = "us-east-1"
bucket_name       = "my-app-data-bucket-06062026"   # must be globally unique
enable_versioning = true
enable_lifecycle  = false

trusted_role_arns = [
  # "arn:aws:iam::123456789012:role/some-external-role"
]

common_tags = {
  ManagedBy   = "Terraform"
  Environment = "dev"
  Project     = "my-app"
  Owner       = "platform-team"
}