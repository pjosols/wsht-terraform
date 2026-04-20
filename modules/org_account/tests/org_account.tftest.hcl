mock_provider "aws" {}

variables {
  account_name     = "test-account"
  email            = "aws+test@example.com"
  sso_instance_arn = "arn:aws:sso:::instance/ssoins-1234567890abcdef"
}

run "plan_succeeds_with_required_vars" {
  command = plan

  assert {
    condition     = aws_organizations_account.this.name == "test-account"
    error_message = "account_name not set correctly"
  }

  assert {
    condition     = aws_organizations_account.this.email == "aws+test@example.com"
    error_message = "email not set correctly"
  }
}

run "billing_defaults_to_deny" {
  command = plan

  assert {
    condition     = aws_organizations_account.this.iam_user_access_to_billing == "DENY"
    error_message = "iam_user_access_to_billing must default to DENY"
  }
}

run "parent_id_accepted" {
  command = plan

  variables {
    parent_id = "ou-ab12-34567890"
  }

  assert {
    condition     = aws_organizations_account.this.parent_id == "ou-ab12-34567890"
    error_message = "parent_id not passed through"
  }
}

run "tags_applied" {
  command = plan

  variables {
    tags = { env = "test" }
  }

  assert {
    condition     = aws_organizations_account.this.tags["env"] == "test"
    error_message = "tags not applied to account"
  }
}

run "no_assignments_creates_no_sso_resources" {
  command = plan

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 0
    error_message = "expected zero SSO assignments when assignments is empty"
  }
}

run "assignments_create_sso_resources" {
  command = plan

  variables {
    assignments = [
      {
        principal_id       = "00000000-0000-0000-0000-000000000001"
        principal_type     = "USER"
        permission_set_arn = "arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-aaaa"
      },
      {
        principal_id       = "00000000-0000-0000-0000-000000000001"
        principal_type     = "USER"
        permission_set_arn = "arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-bbbb"
      },
    ]
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 2
    error_message = "expected 2 SSO assignments"
  }

  assert {
    condition     = contains(keys(aws_ssoadmin_account_assignment.this), "00000000-0000-0000-0000-000000000001/arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-aaaa")
    error_message = "for_each key format is wrong"
  }
}

run "outputs_not_null" {
  command = apply

  assert {
    condition     = output.account_id != null
    error_message = "account_id output must not be null"
  }

  assert {
    condition     = output.account_arn != null
    error_message = "account_arn output must not be null"
  }
}
