locals {
  # SNS topic placeholder — callers supply a real ARN
  sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:${var.name}-alerts"
}

module "kms" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/kms?ref=v1.0.0"

  name        = var.name
  description = "KMS key for ${var.name} Lambda and API Gateway logs"

  service_principals = [
    "logs.us-east-1.amazonaws.com",
  ]

  tags = var.tags
}

module "lambda" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/lambda_container?ref=v1.0.0"

  name      = var.name
  image_uri = var.image_uri

  kms_key_arn = module.kms.key_arn

  iam_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowKmsDecrypt"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = module.kms.key_arn
      }
    ]
  })

  tags = var.tags
}

module "apigw" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/apigw?ref=v1.0.0"

  name                 = var.name
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  kms_key_arn          = module.kms.key_arn

  routes = [
    { method = "GET", path = "/health" },
    { method = "POST", path = "/api/{proxy+}" },
  ]

  tags = var.tags
}

module "monitoring" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/monitoring?ref=v1.0.0"

  lambda_function_name = module.lambda.function_name
  lambda_function_arn  = module.lambda.function_arn
  lambda_timeout       = 30
  sns_topic_arn        = local.sns_topic_arn

  tags = var.tags
}

output "api_endpoint" {
  description = "API Gateway endpoint URL."
  value       = module.apigw.api_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name."
  value       = module.lambda.function_name
}
