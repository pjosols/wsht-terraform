/**
 * Provision S3 bucket and DynamoDB table for Terraform remote state backend.
 *
 * The S3 bucket is created via the s3_bucket module (versioning, encryption,
 * SSL-only policy, and public access block included). The DynamoDB table uses
 * PAY_PER_REQUEST billing with point-in-time recovery and optional KMS encryption.
 */

data "aws_region" "current" {}

locals {
  bucket_name = coalesce(var.bucket_name, "${var.project}-tfstate")
  table_name  = coalesce(var.table_name, "${var.project}-tfstate-lock")
}

module "bucket" {
  source = "../s3_bucket"

  name        = local.bucket_name
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

resource "aws_dynamodb_table" "this" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  tags         = var.tags

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  # nosemgrep: terraform.aws.security.aws-dynamodb-table-unencrypted.aws-dynamodb-table-unencrypted
  # CMK encryption is applied via dynamic block when kms_key_arn is provided; AWS-managed otherwise.
  dynamic "server_side_encryption" {
    for_each = var.kms_key_arn != null ? [var.kms_key_arn] : []
    content {
      enabled     = true
      kms_key_arn = server_side_encryption.value
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
