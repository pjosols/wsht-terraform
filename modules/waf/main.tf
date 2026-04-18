/**
 * Provision WAF Web ACL with rate limiting and AWS managed rule groups.
 *
 * Creates WAF Web ACL with rate limiting at priority 0, AWS Managed Rules
 * (Common Rule Set + Known Bad Inputs) at priority 1-2, and optional additional
 * managed rules starting at priority 10. Must be deployed in us-east-1.
 */

locals {
  # Built-in managed rules always included.
  default_managed_rules = {
    "AWSManagedRulesCommonRuleSet" = {
      priority      = 1
      metric_suffix = "common-rules"
      vendor_name   = "AWS"
      version       = ""
    }
    "AWSManagedRulesKnownBadInputsRuleSet" = {
      priority      = 2
      metric_suffix = "bad-inputs"
      vendor_name   = "AWS"
      version       = ""
    }
  }

  # Merge additional managed rules, starting at priority 10 to avoid collisions.
  extra_managed_rules = {
    for r in var.additional_managed_rules : r.name => r
  }

  all_managed_rules = merge(local.default_managed_rules, local.extra_managed_rules)
}

resource "aws_wafv2_web_acl" "this" {
  provider    = aws.us_east_1
  name        = var.name
  description = "WAF Web ACL for CloudFront — ${var.name}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rate limiting rule — always priority 0 (evaluated first).
  rule {
    name     = "rate-limit"
    priority = 0

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = local.all_managed_rules
    content {
      name     = rule.key
      priority = rule.value.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.key
          vendor_name = rule.value.vendor_name
          version     = rule.value.version != "" ? rule.value.version : null
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name}-${rule.value.metric_suffix}"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.name
    sampled_requests_enabled   = true
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}
