/**
 * Provision Lambda function with ECR image, CloudWatch logs, and IAM role.
 *
 * Creates ECR repository with image scanning and lifecycle policy, CloudWatch
 * log group with KMS encryption, IAM role with base permissions (logs, ECR),
 * and Lambda function with arm64 architecture, X-Ray tracing, and optional
 * VPC configuration. Caller supplies image_uri and iam_policy_json.
 */

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.ecr_keep_image_count} images"
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = var.ecr_keep_image_count }
      action       = { type = "expire" }
    }]
  })
}

# checkov:skip=CKV_AWS_338: retention period is caller-controlled; default 30 days is intentional
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = var.tags
}

resource "aws_iam_role" "this" {
  name                 = "${var.name}-lambda"
  permissions_boundary = var.permissions_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "logs_and_ecr" {
  name = "${var.name}-lambda-base"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.this.arn}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:BatchCheckLayerAvailability"]
        Resource = aws_ecr_repository.this.arn
      },
      {
        # ecr:GetAuthorizationToken is required for Lambda to authenticate with ECR when pulling
        # its container image. It does not support resource-level restrictions (must be "*").
        # The token is short-lived (12h) and scoped to the ECR service only.
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"] # nosemgrep: terraform.lang.security.iam.no-iam-creds-exposure.no-iam-creds-exposure
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "caller" {
  name   = "${var.name}-lambda-policy"
  role   = aws_iam_role.this.id
  policy = var.iam_policy_json
}

# checkov:skip=CKV_AWS_272: code_signing_config_arn is not supported for image-based (container) Lambda functions; package_type = "Image" is enforced by this module
resource "aws_lambda_function" "this" {
  function_name                  = var.name
  role                           = aws_iam_role.this.arn
  package_type                   = "Image"
  image_uri                      = var.image_uri
  timeout                        = var.timeout
  memory_size                    = var.memory_size
  architectures                  = ["arm64"]
  kms_key_arn                    = var.kms_key_arn # nosemgrep: terraform.aws.security.aws-lambda-environment-unencrypted.aws-lambda-environment-unencrypted -- caller supplies customer-managed KMS key via kms_key_arn
  reserved_concurrent_executions = var.reserved_concurrent_executions

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_arn != null ? [var.dead_letter_arn] : []
    content {
      target_arn = dead_letter_config.value
    }
  }

  ephemeral_storage {
    size = var.ephemeral_storage_mb
  }

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  tracing_config {
    mode = "Active"
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  depends_on = [aws_cloudwatch_log_group.this]

  lifecycle {
    ignore_changes = [image_uri]
  }

  tags = var.tags
}
