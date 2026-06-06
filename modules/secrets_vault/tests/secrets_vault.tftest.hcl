mock_provider "aws" {}

variables {
  name               = "myapp"
  path_prefix        = "appw/prod"
  trusted_principals = ["arn:aws:iam::222222222222:root"]
}

# Plan succeeds with required variables only
run "plan_succeeds_with_required_vars" {
  command = plan
}

# Reader role is named per-app: <name>-secrets-reader
run "reader_role_named_per_app" {
  command = plan

  assert {
    condition     = aws_iam_role.reader.name == "myapp-secrets-reader"
    error_message = "reader role must be named <name>-secrets-reader"
  }
}

# Read policy is scoped to this app's path prefix only, and grants GetSecretValue
run "read_policy_scoped_to_path_prefix" {
  command = plan

  assert {
    condition     = endswith(output.secret_arn_wildcard, "secret:appw/prod/*")
    error_message = "reader role must be scoped to <path_prefix>/* secrets"
  }

  assert {
    condition     = endswith(jsondecode(aws_iam_role_policy.read.policy).Statement[0].Resource, "secret:appw/prod/*")
    error_message = "read policy Resource must be the <path_prefix>/* wildcard"
  }

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_role_policy.read.policy).Statement :
      contains(s.Action, "secretsmanager:GetSecretValue") if s.Sid == "ReadAppSecrets"
    ])
    error_message = "read policy must grant secretsmanager:GetSecretValue"
  }
}

# Trust policy includes the caller-supplied principals
run "trusts_provided_principals" {
  command = plan

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_role.reader.assume_role_policy).Statement :
      contains(s.Principal.AWS, "arn:aws:iam::222222222222:root")
    ])
    error_message = "assume role policy must trust the provided principal"
  }
}

# No ExternalId condition by default
run "no_external_id_condition_by_default" {
  command = plan

  assert {
    condition = alltrue([
      for s in jsondecode(aws_iam_role.reader.assume_role_policy).Statement : !can(s.Condition)
    ])
    error_message = "no ExternalId condition should be present when external_id is unset"
  }
}

# ExternalId condition added when external_id is set
run "external_id_condition_when_set" {
  command = plan

  variables {
    external_id = "my-secret-external-id"
  }

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_role.reader.assume_role_policy).Statement :
      try(s.Condition.StringEquals["sts:ExternalId"] == "my-secret-external-id", false)
    ])
    error_message = "ExternalId condition must be present and match when external_id is set"
  }
}

# No secrets created by default
run "no_secrets_created_by_default" {
  command = plan

  assert {
    condition     = length(aws_secretsmanager_secret.this) == 0
    error_message = "no secrets should be created when the secrets map is empty"
  }
}

# Secrets are created under <path_prefix>/<key>
run "secrets_created_under_path_prefix" {
  command = plan

  variables {
    secrets = {
      db-password = { description = "DB password" }
      api-key     = { description = "API key" }
    }
  }

  assert {
    condition     = aws_secretsmanager_secret.this["db-password"].name == "appw/prod/db-password"
    error_message = "secret name must be <path_prefix>/<key>"
  }

  assert {
    condition     = length(aws_secretsmanager_secret.this) == 2
    error_message = "both secret containers must be created"
  }
}

# Validation: path_prefix rejects a trailing slash
run "rejects_path_prefix_with_trailing_slash" {
  command = plan

  variables {
    path_prefix = "appw/prod/"
  }

  expect_failures = [var.path_prefix]
}

# Validation: trusted_principals must be non-empty
run "rejects_empty_trusted_principals" {
  command = plan

  variables {
    trusted_principals = []
  }

  expect_failures = [var.trusted_principals]
}

# Validation: recovery_window_days must be 0 or 7-30
run "rejects_bad_recovery_window" {
  command = plan

  variables {
    recovery_window_days = 3
  }

  expect_failures = [var.recovery_window_days]
}

# Validation: max_session_duration must be 3600-43200
run "rejects_bad_session_duration" {
  command = plan

  variables {
    max_session_duration = 100
  }

  expect_failures = [var.max_session_duration]
}
