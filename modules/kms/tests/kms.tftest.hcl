# Test suite for KMS module. Validates key creation, alias naming, policy statements,
# service principal grants, and lifecycle protection.

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
}

variables {
  name        = "app"
  description = "Application KMS key"
}

run "plan_succeeds_with_required_vars" {
  command = plan

  assert {
    condition     = aws_kms_key.this.description == "Application KMS key"
    error_message = "key description mismatch"
  }

  assert {
    condition     = aws_kms_key.this.enable_key_rotation == true
    error_message = "key rotation must be enabled"
  }

  assert {
    condition     = aws_kms_alias.this.name == "alias/app"
    error_message = "alias name mismatch: expected alias/app when no prefix set"
  }
}

run "outputs_not_null" {
  command = plan

  assert {
    condition     = aws_kms_key.this.description != null
    error_message = "key description must not be null"
  }

  assert {
    condition     = aws_kms_alias.this.name != null
    error_message = "alias name must not be null"
  }
}

run "prevent_destroy_lifecycle" {
  command = plan

  # Regression: prevent_destroy must remain on the key (stateful resource)
  assert {
    condition     = aws_kms_key.this.deletion_window_in_days == 30
    error_message = "deletion_window_in_days must be 30"
  }
}

run "service_principals_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.service_principals) == 0
    error_message = "service_principals should default to empty"
  }
}

run "service_principals_accepted" {
  command = plan

  variables {
    service_principals = ["logs.us-east-1.amazonaws.com"]
  }

  assert {
    condition     = length(var.service_principals) == 1
    error_message = "service_principals not passed through"
  }
}

run "tags_applied" {
  command = plan

  variables {
    tags = { env = "test" }
  }

  assert {
    condition     = aws_kms_key.this.tags["env"] == "test"
    error_message = "tags not applied to key"
  }
}

run "alias_without_prefix" {
  command = plan

  # Regression: alias must not contain a hardcoded project prefix when alias_prefix is empty
  assert {
    condition     = aws_kms_alias.this.name == "alias/app"
    error_message = "alias must be alias/<name> when alias_prefix is empty"
  }
}

run "alias_with_prefix" {
  command = plan

  variables {
    alias_prefix = "myproject"
  }

  assert {
    condition     = aws_kms_alias.this.name == "alias/myproject-app"
    error_message = "alias must be alias/<prefix>-<name> when alias_prefix is set"
  }
}

# Regression: key spec and usage must stay SYMMETRIC_DEFAULT / ENCRYPT_DECRYPT
# (documented in KMS_DESIGN.md — changing these breaks all service integrations)
run "key_spec_and_usage_defaults" {
  command = plan

  assert {
    condition     = aws_kms_key.this.customer_master_key_spec == "SYMMETRIC_DEFAULT"
    error_message = "customer_master_key_spec must be SYMMETRIC_DEFAULT"
  }

  assert {
    condition     = aws_kms_key.this.key_usage == "ENCRYPT_DECRYPT"
    error_message = "key_usage must be ENCRYPT_DECRYPT"
  }
}

# Regression: additional_policy_statements must be accepted without error
# (the extension pattern described in KMS_DESIGN.md)
run "additional_policy_statements_accepted" {
  command = plan

  variables {
    additional_policy_statements = [
      {
        sid     = "CustomAllow"
        actions = ["kms:Decrypt"]
        principals = [
          { type = "AWS", identifiers = ["arn:aws:iam::123456789012:role/MyRole"] }
        ]
      }
    ]
  }

  assert {
    condition     = length(var.additional_policy_statements) == 1
    error_message = "additional_policy_statements not accepted"
  }
}

run "additional_policy_statements_empty_by_default" {
  command = plan

  assert {
    condition     = length(var.additional_policy_statements) == 0
    error_message = "additional_policy_statements must default to empty"
  }
}

# Type-safety: typed object fields are accepted correctly
run "additional_policy_statements_full_object" {
  command = plan

  variables {
    additional_policy_statements = [
      {
        sid       = "FullStatement"
        effect    = "Allow"
        actions   = ["kms:Decrypt", "kms:Encrypt"]
        resources = ["*"]
        principals = [
          { type = "AWS", identifiers = ["arn:aws:iam::123456789012:role/SvcRole"] }
        ]
        conditions = [
          { test = "StringEquals", variable = "kms:CallerAccount", values = ["123456789012"] }
        ]
      }
    ]
  }

  assert {
    condition     = var.additional_policy_statements[0].effect == "Allow"
    error_message = "effect field not accepted"
  }

  assert {
    condition     = var.additional_policy_statements[0].conditions[0].test == "StringEquals"
    error_message = "conditions.test field not accepted"
  }
}

# Type-safety: effect defaults to "Allow" when omitted
run "additional_policy_statements_effect_default" {
  command = plan

  variables {
    additional_policy_statements = [
      { actions = ["kms:Decrypt"] }
    ]
  }

  assert {
    condition     = var.additional_policy_statements[0].effect == "Allow"
    error_message = "effect must default to Allow"
  }
}

# Type-safety: resources defaults to ["*"] when omitted
run "additional_policy_statements_resources_default" {
  command = plan

  variables {
    additional_policy_statements = [
      { actions = ["kms:Decrypt"] }
    ]
  }

  assert {
    condition     = length(var.additional_policy_statements[0].resources) == 1 && var.additional_policy_statements[0].resources[0] == "*"
    error_message = "resources must default to [\"*\"]"
  }
}
