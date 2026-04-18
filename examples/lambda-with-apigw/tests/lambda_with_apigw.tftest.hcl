mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-east-1:123456789012:key/mock-key-id"
      key_id = "mock-key-id"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-lambda-role"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/mock/log-group"
    }
  }

  mock_resource "aws_apigatewayv2_api" {
    defaults = {
      id            = "mockapi123"
      api_endpoint  = "https://mockapi123.execute-api.us-east-1.amazonaws.com"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:mockapi123"
    }
  }
}

# Verify the composition plans successfully with defaults.
run "plan_succeeds_with_defaults" {
  command = plan

  assert {
    condition     = module.lambda.function_name == "my-service"
    error_message = "lambda function_name must equal var.name"
  }
}

# Verify custom variable values are wired through correctly.
run "plan_succeeds_with_custom_values" {
  command = plan

  variables {
    name      = "custom-svc"
    image_uri = "111122223333.dkr.ecr.us-east-1.amazonaws.com/custom-svc:v1"
    tags = {
      env = "staging"
    }
  }

  assert {
    condition     = module.lambda.function_name == "custom-svc"
    error_message = "lambda function_name must equal var.name"
  }
}
