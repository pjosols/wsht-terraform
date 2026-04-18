mock_provider "aws" {
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/apigateway/test-api"
    }
  }
  mock_resource "aws_apigatewayv2_api" {
    defaults = {
      id            = "abc123"
      api_endpoint  = "https://abc123.execute-api.us-east-1.amazonaws.com"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:abc123"
    }
  }
  mock_resource "aws_apigatewayv2_stage" {
    defaults = {
      id = "$default"
    }
  }
}

variables {
  name                 = "test-api"
  lambda_invoke_arn    = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:test/invocations"
  lambda_function_name = "test-function"
  routes = [
    { method = "GET", path = "/health" }
  ]
}

# All outputs are set after apply
run "outputs_not_null" {
  command = apply
  assert {
    condition     = output.api_id != null
    error_message = "api_id must not be null"
  }
  assert {
    condition     = output.api_endpoint != null
    error_message = "api_endpoint must not be null"
  }
  assert {
    condition     = output.execution_arn != null
    error_message = "execution_arn must not be null"
  }
  assert {
    condition     = output.stage_id != null
    error_message = "stage_id must not be null"
  }
}

# Access logging is always configured (security default — regression guard)
run "access_logging_always_enabled" {
  command = plan
  assert {
    condition     = aws_cloudwatch_log_group.access.name == "/aws/apigateway/test-api"
    error_message = "log group name must follow /aws/apigateway/<name> convention"
  }
  assert {
    condition     = aws_cloudwatch_log_group.access.retention_in_days == 365
    error_message = "default log retention must be 365 days"
  }
}

# CORS disabled by default
run "cors_disabled_by_default" {
  command = plan
  assert {
    condition     = length(aws_apigatewayv2_api.this.cors_configuration) == 0
    error_message = "CORS must be disabled when cors_config is null"
  }
}

# CORS enabled when config provided
run "cors_enabled_when_configured" {
  command = plan
  variables {
    cors_config = {
      allow_origins = ["https://example.com"]
      allow_methods = ["GET", "POST"]
      allow_headers = ["Content-Type"]
    }
  }
  assert {
    condition     = length(aws_apigatewayv2_api.this.cors_configuration) == 1
    error_message = "CORS must be configured when cors_config is provided"
  }
}

# Optional CORS fields default correctly when omitted (regression: direct attribute access relies on typed optional() defaults)
run "cors_optional_fields_default_values" {
  command = plan
  variables {
    cors_config = {
      allow_origins = ["https://example.com"]
      allow_methods = ["GET"]
      allow_headers = ["Content-Type"]
    }
  }
  assert {
    condition     = length(aws_apigatewayv2_api.this.cors_configuration[0].expose_headers) == 0
    error_message = "expose_headers must default to []"
  }
  assert {
    condition     = aws_apigatewayv2_api.this.cors_configuration[0].max_age == 300
    error_message = "max_age must default to 300"
  }
  assert {
    condition     = aws_apigatewayv2_api.this.cors_configuration[0].allow_credentials == false
    error_message = "allow_credentials must default to false"
  }
}

# Optional CORS fields accept explicit non-default values
run "cors_optional_fields_explicit_values" {
  command = plan
  variables {
    cors_config = {
      allow_origins     = ["https://example.com"]
      allow_methods     = ["GET"]
      allow_headers     = ["Content-Type"]
      expose_headers    = ["X-Custom-Header"]
      max_age           = 600
      allow_credentials = true
    }
  }
  assert {
    condition     = aws_apigatewayv2_api.this.cors_configuration[0].expose_headers == toset(["X-Custom-Header"])
    error_message = "expose_headers must reflect the provided value"
  }
  assert {
    condition     = aws_apigatewayv2_api.this.cors_configuration[0].max_age == 600
    error_message = "max_age must reflect the provided value"
  }
  assert {
    condition     = aws_apigatewayv2_api.this.cors_configuration[0].allow_credentials == true
    error_message = "allow_credentials must reflect the provided value"
  }
}

# JWT authorizer is created
run "jwt_authorizer_created" {
  command = plan
  variables {
    authorizer_configs = {
      cognito = {
        type             = "JWT"
        name             = "cognito"
        identity_sources = ["$request.header.Authorization"]
        jwt = {
          audience = ["client-id"]
          issuer   = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_abc"
        }
      }
    }
    routes = [
      { method = "GET", path = "/protected", authorizer = "cognito" }
    ]
  }
  assert {
    condition     = length(aws_apigatewayv2_authorizer.this) == 1
    error_message = "one authorizer must be created"
  }
}

# No authorizers when authorizer_configs is empty
run "no_authorizers_by_default" {
  command = plan
  assert {
    condition     = length(aws_apigatewayv2_authorizer.this) == 0
    error_message = "no authorizers should be created when authorizer_configs is empty"
  }
}

# One route resource per route entry
run "routes_created" {
  command = plan
  variables {
    routes = [
      { method = "GET", path = "/a" },
      { method = "POST", path = "/b" },
    ]
  }
  assert {
    condition     = length(aws_apigatewayv2_route.this) == 2
    error_message = "one route resource must be created per route entry"
  }
}

# Extra lambda permissions are created
run "extra_lambda_permissions_created" {
  command = plan
  variables {
    extra_lambda_permissions = {
      authorizer = "auth-function"
    }
  }
  assert {
    condition     = length(aws_lambda_permission.extra) == 1
    error_message = "extra lambda permission must be created"
  }
}

# KMS key ARN is passed to log group
run "kms_key_applied_to_log_group" {
  command = plan
  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
  }
  assert {
    condition     = aws_cloudwatch_log_group.access.kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
    error_message = "KMS key ARN must be set on the log group"
  }
}

# REQUEST authorizer is created with Lambda URI
run "request_authorizer_created" {
  command = plan
  variables {
    authorizer_configs = {
      custom_auth = {
        type             = "REQUEST"
        name             = "custom-auth"
        identity_sources = ["$request.header.X-Token"]
        authorizer_uri   = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:auth/invocations"
      }
    }
    routes = [
      { method = "GET", path = "/secure", authorizer = "custom_auth" }
    ]
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.this["custom_auth"].authorizer_type == "REQUEST"
    error_message = "authorizer type must be REQUEST"
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.this["custom_auth"].authorizer_uri == "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:auth/invocations"
    error_message = "authorizer_uri must be set for REQUEST authorizer"
  }
}

# JWT route gets authorization_type = JWT
run "jwt_route_authorization_type" {
  command = plan
  variables {
    authorizer_configs = {
      cognito = {
        type             = "JWT"
        name             = "cognito"
        identity_sources = ["$request.header.Authorization"]
        jwt = {
          audience = ["client-id"]
          issuer   = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_abc"
        }
      }
    }
    routes = [
      { method = "GET", path = "/protected", authorizer = "cognito" }
    ]
  }
  assert {
    condition     = aws_apigatewayv2_route.this["GET /protected"].authorization_type == "JWT"
    error_message = "route referencing a JWT authorizer must have authorization_type JWT"
  }
}

# REQUEST route gets authorization_type = CUSTOM
run "request_route_authorization_type" {
  command = plan
  variables {
    authorizer_configs = {
      custom_auth = {
        type             = "REQUEST"
        name             = "custom-auth"
        identity_sources = ["$request.header.X-Token"]
        authorizer_uri   = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:auth/invocations"
      }
    }
    routes = [
      { method = "POST", path = "/action", authorizer = "custom_auth" }
    ]
  }
  assert {
    condition     = aws_apigatewayv2_route.this["POST /action"].authorization_type == "CUSTOM"
    error_message = "route referencing a REQUEST authorizer must have authorization_type CUSTOM"
  }
}

# Unauthenticated route gets authorization_type = NONE
run "unauthenticated_route_authorization_type" {
  command = plan
  assert {
    condition     = aws_apigatewayv2_route.this["GET /health"].authorization_type == "NONE"
    error_message = "route with no authorizer must have authorization_type NONE"
  }
}

# extra_lambda_permissions grants invoke to REQUEST authorizer Lambda
run "extra_lambda_permissions_for_request_authorizer" {
  command = plan
  variables {
    authorizer_configs = {
      custom_auth = {
        type             = "REQUEST"
        name             = "custom-auth"
        identity_sources = ["$request.header.X-Token"]
        authorizer_uri   = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:auth/invocations"
      }
    }
    extra_lambda_permissions = {
      custom_auth = "auth-function"
    }
    routes = [
      { method = "GET", path = "/secure", authorizer = "custom_auth" }
    ]
  }
  assert {
    condition     = aws_lambda_permission.extra["custom_auth"].function_name == "auth-function"
    error_message = "extra permission must target the REQUEST authorizer Lambda function"
  }
  assert {
    condition     = aws_lambda_permission.extra["custom_auth"].principal == "apigateway.amazonaws.com"
    error_message = "extra permission principal must be apigateway.amazonaws.com"
  }
}

# throttling_burst_limit rejects zero
run "throttling_burst_limit_rejects_zero" {
  command = plan
  variables {
    throttling_burst_limit = 0
  }
  expect_failures = [var.throttling_burst_limit]
}

# throttling_burst_limit rejects negative
run "throttling_burst_limit_rejects_negative" {
  command = plan
  variables {
    throttling_burst_limit = -1
  }
  expect_failures = [var.throttling_burst_limit]
}

# throttling_rate_limit rejects zero
run "throttling_rate_limit_rejects_zero" {
  command = plan
  variables {
    throttling_rate_limit = 0
  }
  expect_failures = [var.throttling_rate_limit]
}

# throttling_rate_limit rejects negative
run "throttling_rate_limit_rejects_negative" {
  command = plan
  variables {
    throttling_rate_limit = -1
  }
  expect_failures = [var.throttling_rate_limit]
}
