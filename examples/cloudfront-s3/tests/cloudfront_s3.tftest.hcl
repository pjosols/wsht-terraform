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

  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:us-east-1:123456789012:certificate/mock-cert-id"
    }
  }

  mock_resource "aws_acm_certificate_validation" {
    defaults = {
      certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/mock-cert-id"
    }
  }

  mock_resource "aws_wafv2_web_acl" {
    defaults = {
      arn = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/mock-waf/mock-id"
      id  = "mock-waf-id"
    }
  }
}

mock_provider "aws" {
  alias = "us_east_1"

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

  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:us-east-1:123456789012:certificate/mock-cert-id"
    }
  }

  mock_resource "aws_acm_certificate_validation" {
    defaults = {
      certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/mock-cert-id"
    }
  }
}

# Verify the composition plans successfully with defaults.
run "plan_succeeds_with_defaults" {
  command = plan

  assert {
    condition     = var.name == "my-site"
    error_message = "default name must be my-site"
  }

  assert {
    condition     = var.domain == "example.com"
    error_message = "default domain must be example.com"
  }
}

# Verify custom variable values are accepted.
run "plan_succeeds_with_custom_values" {
  command = plan

  variables {
    name   = "my-corp-site"
    domain = "www.example.com"
    tags = {
      env = "prod"
    }
  }

  assert {
    condition     = var.name == "my-corp-site"
    error_message = "name must match provided value"
  }

  assert {
    condition     = var.domain == "www.example.com"
    error_message = "domain must match provided value"
  }
}
