mock_provider "aws" {}

variables {
  name                = "test-pool"
  explicit_auth_flows = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

# Plan succeeds with required variables only
run "plan_succeeds_with_required_vars" {
  command = plan

  assert {
    condition     = aws_cognito_user_pool.this.name == "test-pool"
    error_message = "user pool name mismatch"
  }

  assert {
    condition     = aws_cognito_user_pool_client.this.name == "test-pool-client"
    error_message = "client name should be <name>-client"
  }
}

# Key outputs are not null (apply needed — IDs unknown at plan time with mock provider)
run "outputs_not_null" {
  command = apply

  assert {
    condition     = output.user_pool_id != null
    error_message = "user_pool_id should not be null"
  }

  assert {
    condition     = output.user_pool_arn != null
    error_message = "user_pool_arn should not be null"
  }

  assert {
    condition     = output.client_id != null
    error_message = "client_id should not be null"
  }
}

# Security defaults: advanced security enforced, MFA optional, admin-only creation
run "security_defaults" {
  command = plan

  assert {
    condition     = aws_cognito_user_pool.this.user_pool_add_ons[0].advanced_security_mode == "ENFORCED"
    error_message = "advanced_security_mode must be ENFORCED"
  }

  assert {
    condition     = aws_cognito_user_pool.this.mfa_configuration == "OPTIONAL"
    error_message = "mfa_configuration must be OPTIONAL"
  }

  assert {
    condition     = aws_cognito_user_pool.this.admin_create_user_config[0].allow_admin_create_user_only == true
    error_message = "allow_admin_create_user_only must be true"
  }
}

# Password policy meets minimum requirements
run "password_policy" {
  command = plan

  assert {
    condition     = aws_cognito_user_pool.this.password_policy[0].minimum_length >= 12
    error_message = "minimum password length must be >= 12"
  }

  assert {
    condition     = aws_cognito_user_pool.this.password_policy[0].require_symbols == true
    error_message = "require_symbols must be true"
  }
}

# Token validity defaults
run "token_validity_defaults" {
  command = plan

  assert {
    condition     = aws_cognito_user_pool_client.this.access_token_validity == 1
    error_message = "default access_token_validity should be 1"
  }

  assert {
    condition     = aws_cognito_user_pool_client.this.refresh_token_validity == 30
    error_message = "default refresh_token_validity should be 30"
  }
}

# Tags are passed through
run "tags_passed_through" {
  variables {
    tags = { env = "test" }
  }

  command = plan

  assert {
    condition     = aws_cognito_user_pool.this.tags["env"] == "test"
    error_message = "tags not passed through to user pool"
  }
}

# Callback and logout URLs are set when provided
run "callback_and_logout_urls" {
  variables {
    callback_urls = ["https://example.com/callback"]
    logout_urls   = ["https://example.com/logout"]
  }

  command = plan

  assert {
    condition     = contains(aws_cognito_user_pool_client.this.callback_urls, "https://example.com/callback")
    error_message = "callback_urls not set correctly"
  }

  assert {
    condition     = contains(aws_cognito_user_pool_client.this.logout_urls, "https://example.com/logout")
    error_message = "logout_urls not set correctly"
  }
}

# Validation: access_token_validity must be > 0
run "access_token_validity_zero_rejected" {
  variables { access_token_validity = 0 }
  command         = plan
  expect_failures = [var.access_token_validity]
}

run "access_token_validity_negative_rejected" {
  variables { access_token_validity = -1 }
  command         = plan
  expect_failures = [var.access_token_validity]
}

# Validation: id_token_validity must be > 0
run "id_token_validity_zero_rejected" {
  variables { id_token_validity = 0 }
  command         = plan
  expect_failures = [var.id_token_validity]
}

run "id_token_validity_negative_rejected" {
  variables { id_token_validity = -5 }
  command         = plan
  expect_failures = [var.id_token_validity]
}

# Validation: refresh_token_validity must be > 0
run "refresh_token_validity_zero_rejected" {
  variables { refresh_token_validity = 0 }
  command         = plan
  expect_failures = [var.refresh_token_validity]
}

run "refresh_token_validity_negative_rejected" {
  variables { refresh_token_validity = -1 }
  command         = plan
  expect_failures = [var.refresh_token_validity]
}
