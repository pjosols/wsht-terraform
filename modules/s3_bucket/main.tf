/**
 * Provision S3 bucket with public access block, encryption, versioning, SSL-only policy, and lifecycle rules.
 *
 * Creates S3 bucket with public access blocked, server-side encryption (KMS or AES256),
 * versioning enabled, SSL-only bucket policy, multipart upload cleanup, optional logging,
 * CORS, accelerate, and event notifications.
 */

resource "aws_s3_bucket" "this" {
  bucket        = var.name
  force_destroy = var.force_destroy
  tags          = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

locals {
  ssl_deny_statement = {
    Sid       = "DenyNonSSL"
    Effect    = "Deny"
    Principal = "*"
    Action    = "s3:*"
    Resource = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
    Condition = {
      Bool = {
        "aws:SecureTransport" = "false"
      }
    }
  }

  decoded_policy = var.policy_json != null ? jsondecode(var.policy_json) : null

  merged_policy = local.decoded_policy != null ? jsonencode(merge(
    local.decoded_policy,
    {
      Statement = concat(
        lookup(local.decoded_policy, "Statement", []),
        [local.ssl_deny_statement]
      )
    }
  )) : jsonencode({ Version = "2012-10-17", Statement = [local.ssl_deny_statement] })
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = local.merged_policy

  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "this" {
  for_each      = var.logging_bucket_id != null ? toset(["enabled"]) : toset([])
  bucket        = aws_s3_bucket.this.id
  target_bucket = var.logging_bucket_id
  target_prefix = "${var.name}/"
}

resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = var.object_ownership != null ? toset(["enabled"]) : toset([])
  bucket   = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_cors_configuration" "this" {
  for_each = var.cors_rules != null ? toset(["enabled"]) : toset([])
  bucket   = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      allowed_headers = cors_rule.value.allowed_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

resource "aws_s3_bucket_accelerate_configuration" "this" {
  for_each = var.accelerate ? toset(["enabled"]) : toset([])
  bucket   = aws_s3_bucket.this.id
  status   = "Enabled"
}

resource "aws_s3_bucket_notification" "this" {
  for_each = var.notification_config != null ? toset(["enabled"]) : toset([])
  bucket   = aws_s3_bucket.this.id

  dynamic "lambda_function" {
    for_each = var.notification_config.lambda_functions
    content {
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }
}
