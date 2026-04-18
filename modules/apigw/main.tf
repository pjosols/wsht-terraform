/**
 * Opinionated HTTP API Gateway (v2) module with Lambda proxy integration.
 *
 * Creates API Gateway HTTP API, $default stage with access logging, Lambda
 * proxy integration, configurable routes, CloudWatch log group, and Lambda
 * invoke permission. Supports multiple named JWT/REQUEST authorizers and CORS.
 */

resource "aws_cloudwatch_log_group" "access" {
  #trivy:ignore:aws-cloudwatch-log-group-unencrypted -- kms_key_id is set; customer-managed KMS key encrypts this log group
  # nosemgrep: terraform.aws.security.aws-cloudwatch-log-group-unencrypted -- kms_key_id is set; customer-managed KMS key encrypts this log group
  name              = "/aws/apigateway/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"
  description   = var.description

  dynamic "cors_configuration" {
    for_each = var.cors_config != null ? [var.cors_config] : []
    content {
      allow_origins     = cors_configuration.value.allow_origins
      allow_methods     = cors_configuration.value.allow_methods
      allow_headers     = cors_configuration.value.allow_headers
      expose_headers    = cors_configuration.value.expose_headers
      max_age           = cors_configuration.value.max_age
      allow_credentials = cors_configuration.value.allow_credentials
    }
  }

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }

  dynamic "route_settings" {
    for_each = {
      for r in var.routes : "${r.method} ${r.path}" => r
      if r.throttling_rate_limit != null || r.throttling_burst_limit != null
    }
    content {
      route_key              = route_settings.key
      throttling_rate_limit  = route_settings.value.throttling_rate_limit
      throttling_burst_limit = route_settings.value.throttling_burst_limit
    }
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      errorMessage   = "$context.error.message"
      integrationErr = "$context.integration.error"
    })
  }

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_authorizer" "this" {
  for_each = var.authorizer_configs

  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = each.value.type
  identity_sources = each.value.identity_sources
  name             = each.value.name

  dynamic "jwt_configuration" {
    for_each = each.value.type == "JWT" ? [each.value.jwt] : []
    content {
      audience = jwt_configuration.value.audience
      issuer   = jwt_configuration.value.issuer
    }
  }

  authorizer_uri                    = each.value.type == "REQUEST" ? each.value.authorizer_uri : null
  authorizer_payload_format_version = each.value.type == "REQUEST" ? each.value.payload_format_version : null
  enable_simple_responses           = each.value.type == "REQUEST" ? each.value.enable_simple_responses : null
  authorizer_result_ttl_in_seconds  = each.value.type == "REQUEST" ? each.value.result_ttl_seconds : null
}

resource "aws_apigatewayv2_route" "this" {
  for_each = { for r in var.routes : "${r.method} ${r.path}" => r }

  api_id    = aws_apigatewayv2_api.this.id
  route_key = "${each.value.method} ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  authorization_type = (
    each.value.authorizer == "NONE" || each.value.authorizer == null ? "NONE" :
    aws_apigatewayv2_authorizer.this[each.value.authorizer].authorizer_type == "JWT" ? "JWT" :
    "CUSTOM"
  )

  authorizer_id = (
    each.value.authorizer != "NONE" && each.value.authorizer != null
    ? aws_apigatewayv2_authorizer.this[each.value.authorizer].id
    : null
  )
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "extra" {
  for_each = var.extra_lambda_permissions

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
