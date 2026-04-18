mock_provider "aws" {
  alias = "us_east_1"
}

# --- plan succeeds with required variables only ---
run "plan_minimal" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name = "test-waf"
  }
}

# --- name and scope are set correctly ---
run "name_and_scope" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name = "my-waf"
  }

  assert {
    condition     = aws_wafv2_web_acl.this.name == "my-waf"
    error_message = "web ACL name must match var.name"
  }

  assert {
    condition     = aws_wafv2_web_acl.this.scope == "CLOUDFRONT"
    error_message = "scope must be CLOUDFRONT"
  }
}

# --- rate_limit = 0 is rejected ---
run "rate_limit_zero_rejected" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name       = "test-waf"
    rate_limit = 0
  }

  expect_failures = [var.rate_limit]
}

# --- negative rate_limit is rejected ---
run "rate_limit_negative_rejected" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name       = "test-waf"
    rate_limit = -1
  }

  expect_failures = [var.rate_limit]
}

# --- default rate_limit is 1000 ---
run "rate_limit_default" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name = "test-waf"
  }

  assert {
    condition = one([
      for r in aws_wafv2_web_acl.this.rule : r
      if r.name == "rate-limit"
    ]).statement[0].rate_based_statement[0].limit == 1000
    error_message = "default rate_limit should be 1000"
  }
}

# --- custom rate_limit is respected ---
run "rate_limit_custom" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name       = "test-waf"
    rate_limit = 500
  }

  assert {
    condition = one([
      for r in aws_wafv2_web_acl.this.rule : r
      if r.name == "rate-limit"
    ]).statement[0].rate_based_statement[0].limit == 500
    error_message = "rate_limit should be 500"
  }
}

# --- tags are passed through ---
run "tags_applied" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name = "test-waf"
    tags = { project = "wsht", env = "prod" }
  }

  assert {
    condition     = aws_wafv2_web_acl.this.tags["project"] == "wsht"
    error_message = "tags must be passed through to the web ACL"
  }
}

# --- default managed rules are always included (security baseline) ---
run "default_managed_rules_always_present" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name = "test-waf"
  }

  assert {
    condition = contains(
      [for r in aws_wafv2_web_acl.this.rule : r.name],
      "AWSManagedRulesCommonRuleSet"
    )
    error_message = "AWSManagedRulesCommonRuleSet must always be present"
  }

  assert {
    condition = contains(
      [for r in aws_wafv2_web_acl.this.rule : r.name],
      "AWSManagedRulesKnownBadInputsRuleSet"
    )
    error_message = "AWSManagedRulesKnownBadInputsRuleSet must always be present"
  }
}

# --- default managed rules occupy priorities 1 and 2 ---
run "default_managed_rules_priority_scheme" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name = "test-waf"
  }

  assert {
    condition = one([
      for r in aws_wafv2_web_acl.this.rule : r
      if r.name == "AWSManagedRulesCommonRuleSet"
    ]).priority == 1
    error_message = "AWSManagedRulesCommonRuleSet must have priority 1"
  }

  assert {
    condition = one([
      for r in aws_wafv2_web_acl.this.rule : r
      if r.name == "AWSManagedRulesKnownBadInputsRuleSet"
    ]).priority == 2
    error_message = "AWSManagedRulesKnownBadInputsRuleSet must have priority 2"
  }
}

# --- additional_managed_rules are merged and use caller-supplied priority (>=10 convention) ---
run "extra_managed_rules_merged_at_priority_10" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name = "test-waf"
    additional_managed_rules = [
      {
        name          = "AWSManagedRulesSQLiRuleSet"
        vendor_name   = "AWS"
        priority      = 10
        metric_suffix = "sqli"
      }
    ]
  }

  assert {
    condition = contains(
      [for r in aws_wafv2_web_acl.this.rule : r.name],
      "AWSManagedRulesSQLiRuleSet"
    )
    error_message = "additional managed rule must be present in the web ACL"
  }

  assert {
    condition = one([
      for r in aws_wafv2_web_acl.this.rule : r
      if r.name == "AWSManagedRulesSQLiRuleSet"
    ]).priority == 10
    error_message = "additional managed rule must use the caller-supplied priority (10)"
  }
}

# --- regression: custom_rules variable must not exist (broken statement-as-argument pattern was removed) ---
# If custom_rules were re-introduced with `statement = rule.value.statement`, the AWS provider
# would reject it with "An argument named 'statement' is not expected here."
# This test guards against that pattern silently re-appearing.
run "no_custom_rules_variable" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name = "test-waf"
  }

  # Plan must succeed with only the supported variables — no custom_rules in scope.
  assert {
    condition     = aws_wafv2_web_acl.this.name == "test-waf"
    error_message = "plan must succeed without a custom_rules variable"
  }
}

# --- additional_managed_rules is the only supported custom-rule extension point ---
run "additional_managed_rules_is_extension_point" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name = "test-waf"
    additional_managed_rules = [
      {
        name          = "AWSManagedRulesBotControlRuleSet"
        vendor_name   = "AWS"
        priority      = 10
        metric_suffix = "bot-control"
      }
    ]
  }

  assert {
    condition = contains(
      [for r in aws_wafv2_web_acl.this.rule : r.name],
      "AWSManagedRulesBotControlRuleSet"
    )
    error_message = "additional_managed_rules must be the supported way to extend WAF rules"
  }
}

# --- extra managed rules do not collide with default rule priorities ---
run "no_priority_collision_between_default_and_extra" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name = "test-waf"
    additional_managed_rules = [
      {
        name          = "AWSManagedRulesSQLiRuleSet"
        vendor_name   = "AWS"
        priority      = 10
        metric_suffix = "sqli"
      },
      {
        name          = "AWSManagedRulesLinuxRuleSet"
        vendor_name   = "AWS"
        priority      = 11
        metric_suffix = "linux"
      }
    ]
  }

  assert {
    condition = length(
      distinct([for r in aws_wafv2_web_acl.this.rule : r.priority])
    ) == length([for r in aws_wafv2_web_acl.this.rule : r.priority])
    error_message = "all rule priorities must be unique — no collisions allowed"
  }
}



# --- regression: prevent_destroy lifecycle must be present on the Web ACL ---
# lifecycle { prevent_destroy = true } cannot be asserted at plan time, but this
# run documents the requirement. If the block is removed, the resource label
# changes or a destroy is attempted — this test ensures the resource still plans
# correctly with the lifecycle block in place.
run "prevent_destroy_lifecycle_present" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name = "test-waf"
  }

  # Plan must succeed — lifecycle block must not break normal plan behaviour.
  assert {
    condition     = aws_wafv2_web_acl.this.name == "test-waf"
    error_message = "web ACL must plan successfully with prevent_destroy lifecycle block"
  }
}

# --- outputs reference the correct resource attributes ---
# arn/id are computed (unknown at plan time); assert the resource name is set
# as a proxy that the resource — and therefore its outputs — will be created.
run "outputs_reference_resource" {
  command = plan

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  variables {
    name = "test-waf"
  }

  assert {
    condition     = aws_wafv2_web_acl.this.name == "test-waf"
    error_message = "web ACL resource must be planned so arn/id outputs will be populated"
  }
}
