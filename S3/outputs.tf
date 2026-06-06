output "bucket_id" {
  description = "The S3 bucket name"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "The S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "bucket_region" {
  description = "AWS region the bucket was created in"
  value       = aws_s3_bucket.main.region
}

output "read_only_role_arn" {
  description = "ARN of the read-only IAM role"
  value       = aws_iam_role.s3_read_only.arn
}

output "read_write_role_arn" {
  description = "ARN of the read-write IAM role"
  value       = aws_iam_role.s3_read_write.arn
}

output "read_only_instance_profile_arn" {
  description = "ARN of the read-only EC2 instance profile"
  value       = aws_iam_instance_profile.s3_read_only.arn
}

output "read_write_instance_profile_arn" {
  description = "ARN of the read-write EC2 instance profile"
  value       = aws_iam_instance_profile.s3_read_write.arn
}