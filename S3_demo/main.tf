# =============================================================
# main.tf - S3 Bucket with IAM Roles & Policies
# Terraform Cloud compatible
# =============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Terraform Cloud backend — update org/workspace names
  cloud {
    organization = "siva9861-demo-org"

    workspaces {
      name = "Terraform_004"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# =============================================================
# S3 Bucket
# =============================================================

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = merge(var.common_tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.enable_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# =============================================================
# S3 Bucket Policy (resource-based)
# =============================================================

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowReadOnlyAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.s3_read_only.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*",
    ]
  }

  statement {
    sid    = "AllowReadWriteAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.s3_read_write.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetObjectVersion",
      "s3:DeleteObjectVersion",
    ]

    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket     = aws_s3_bucket.main.id
  policy     = data.aws_iam_policy_document.bucket_policy.json
  depends_on = [aws_s3_bucket_public_access_block.main]
}

# =============================================================
# IAM: Assume Role Policy (trust relationship)
# =============================================================

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cross_account_assume_role" {
  count = length(var.trusted_role_arns) > 0 ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.trusted_role_arns
    }
  }
}

# =============================================================
# IAM Role: Read-Only
# =============================================================

resource "aws_iam_role" "s3_read_only" {
  name               = "${var.bucket_name}-read-only-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  description        = "Read-only access to ${var.bucket_name} S3 bucket"

  tags = var.common_tags
}

data "aws_iam_policy_document" "s3_read_only" {
  statement {
    sid    = "ListBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketVersions",
    ]

    resources = [aws_s3_bucket.main.arn]
  }

  statement {
    sid    = "GetObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
    ]

    resources = ["${aws_s3_bucket.main.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_read_only" {
  name        = "${var.bucket_name}-read-only-policy"
  description = "Read-only access to ${var.bucket_name}"
  policy      = data.aws_iam_policy_document.s3_read_only.json

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.s3_read_only.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}

# =============================================================
# IAM Role: Read-Write
# =============================================================

resource "aws_iam_role" "s3_read_write" {
  name               = "${var.bucket_name}-read-write-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  description        = "Read-write access to ${var.bucket_name} S3 bucket"

  tags = var.common_tags
}

data "aws_iam_policy_document" "s3_read_write" {
  statement {
    sid    = "ListBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketVersions",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [aws_s3_bucket.main.arn]
  }

  statement {
    sid    = "ReadWriteObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]

    resources = ["${aws_s3_bucket.main.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_read_write" {
  name        = "${var.bucket_name}-read-write-policy"
  description = "Read-write access to ${var.bucket_name}"
  policy      = data.aws_iam_policy_document.s3_read_write.json

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_read_write" {
  role       = aws_iam_role.s3_read_write.name
  policy_arn = aws_iam_policy.s3_read_write.arn
}

# =============================================================
# IAM Instance Profiles (for EC2 attachment)
# =============================================================

resource "aws_iam_instance_profile" "s3_read_only" {
  name = "${var.bucket_name}-read-only-profile"
  role = aws_iam_role.s3_read_only.name
}

resource "aws_iam_instance_profile" "s3_read_write" {
  name = "${var.bucket_name}-read-write-profile"
  role = aws_iam_role.s3_read_write.name
}