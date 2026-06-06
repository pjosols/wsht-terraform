mock_provider "aws" {}

variables {
  path_prefix        = "appw/prod"
  trusted_principals = ["arn:aws:iam::222222222222:root"]
}

# Plan succeeds with required variables only
run "plan_succeeds_with_required_vars" {
  command = plan
}

# Reader role + policy names are derived from path_prefix when name is unset
run "names_derived_from_path_prefix" {
  command = plan

  assert {
    condition     = aws_iam_role.reader.name == "appw-prod-secrets-reader"
    error_message = "reader role name must derive from path_prefix (appw/prod -> appw-prod-secrets-reader)"
  }

  assert {
    condition     = aws_iam_role_policy.read.name == "appw-prod-secrets-read"
    error_message = "inline policy name must derive from path_prefix (appw-prod-secrets-read)"
  }
}

# An explicit name overrides the derived base
run "name_override_wins" {
  command = plan

  variables {
    name = "custom"
  }

  assert {
    condition     = aws_iam_role.reader.name == "custom-secrets-reader"
    error_message = "explicit name must override the derived base"
  }

  assert {
    condition     = aws_iam_role_policy.read.name == "custom-secrets-read"
    error_message = "explicit name must drive the inline policy name too"
  }
}

# App/Environment tags are derived from the <app>/<env> segments
run "tags_derived_from_segments" {
  command = plan

  assert {
    condition     = aws_iam_role.reader.tags["App"] == "appw"
    error_message = "App tag must be the first path segment (appw)"
  }

  assert {
    condition     = aws_iam_role.reader.tags["Environment"] == "prod"
    error_message = "Environment tag must be the second path segment (prod)"
  }
}

# No Environment tag when the prefix has no env segment
run "no_environment_tag_without_env_segment" {
  command = plan

  variables {
    path_prefix = "appw"
  }

  assert {
    condition     = aws_iam_role.reader.name == "appw-secrets-reader"
    error_message = "env-less prefix must still derive a role name"
  }

  assert {
    condition     = !contains(keys(aws_iam_role.reader.tags), "Environment")
    error_message = "Environment tag must be absent when the prefix has no env segment"
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
