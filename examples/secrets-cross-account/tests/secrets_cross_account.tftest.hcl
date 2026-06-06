mock_provider "aws" {}

mock_provider "aws" {
  alias = "app"

  # The role-policy attachment validates ARN format, so the generated policy needs a
  # real-looking ARN under apply.
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::222222222222:policy/appw-secrets-access"
    }
  }
}

# The composition applies cleanly and exports the reader role ARN (computed, so
# resolved on apply under the mock provider).
run "apply_succeeds_with_defaults" {
  command = apply

  assert {
    condition     = output.reader_role_arn != null
    error_message = "reader role ARN must be exported"
  }
}

# Custom account and workload role are accepted.
run "plan_succeeds_with_custom_values" {
  command = plan

  variables {
    app_account_id         = "333333333333"
    app_workload_role_name = "appw-lambda"
    tags                   = { project = "appw" }
  }

  assert {
    condition     = var.app_account_id == "333333333333"
    error_message = "app_account_id must accept a custom value"
  }
}
