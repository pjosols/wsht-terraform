mock_provider "aws" {}

variables {
  name            = "myapp"
  vault_role_arns = ["arn:aws:iam::111111111111:role/myapp-secrets-reader"]
}

# Plan succeeds with required variables only
run "plan_succeeds_with_required_vars" {
  command = plan
}

# Policy is named per-app: <name>-secrets-access
run "policy_named_per_app" {
  command = plan

  assert {
    condition     = aws_iam_policy.this.name == "myapp-secrets-access"
    error_message = "policy must be named <name>-secrets-access"
  }
}

# Policy grants sts:AssumeRole on the supplied vault reader role ARNs
run "policy_grants_assume_role_on_vault_arns" {
  command = plan

  assert {
    condition = anytrue([
      for s in jsondecode(output.policy_json).Statement :
      s.Action == "sts:AssumeRole" && contains(s.Resource, "arn:aws:iam::111111111111:role/myapp-secrets-reader")
    ])
    error_message = "policy must grant sts:AssumeRole on the vault reader role ARN"
  }
}

# No attachments created by default
run "no_attachments_by_default" {
  command = plan

  assert {
    condition     = length(aws_iam_role_policy_attachment.this) == 0
    error_message = "no attachments should be created when attach_to_role_names is empty"
  }
}

# Policy is attached to each provided role, keyed by role name
run "attaches_to_provided_roles" {
  command = plan

  variables {
    attach_to_role_names = ["my-lambda-role", "my-ecs-task-role"]
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.this) == 2
    error_message = "must attach the policy to each provided role"
  }

  assert {
    condition     = contains(keys(aws_iam_role_policy_attachment.this), "my-lambda-role")
    error_message = "attachment must use the role name as the for_each key"
  }
}

# Validation: vault_role_arns must be non-empty
run "rejects_empty_vault_role_arns" {
  command = plan

  variables {
    vault_role_arns = []
  }

  expect_failures = [var.vault_role_arns]
}
