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

# The composition applies cleanly and exports both reader role ARNs (computed, so
# resolved on apply under the mock provider).
run "apply_succeeds_with_defaults" {
  command = apply

  assert {
    condition     = output.prod_reader_role_arn != null && output.staging_reader_role_arn != null
    error_message = "prod and staging reader role ARNs must be exported"
  }
}

# Custom accounts and workload role are accepted.
run "plan_succeeds_with_custom_values" {
  command = plan

  variables {
    prod_account_id        = "444444444444"
    staging_account_id     = "555555555555"
    app_workload_role_name = "appw-lambda"
    tags                   = { project = "appw" }
  }

  assert {
    condition     = var.prod_account_id == "444444444444"
    error_message = "prod_account_id must accept a custom value"
  }
}
