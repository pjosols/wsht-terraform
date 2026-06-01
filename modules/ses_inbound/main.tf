/**
 * Configure SES inbound email receipt for a domain, storing raw emails to S3.
 *
 * Creates an SES domain identity, receipt rule set, and receipt rule. Does not
 * provision the S3 bucket — the caller is responsible for creating it and passing
 * bucket_policy_json (output) to the s3_bucket module's policy_json input so SES
 * has write access.
 *
 * SES inbound email receipt is only available in us-east-1, us-west-2, and eu-west-1.
 */

data "aws_caller_identity" "current" {}

locals {
  domain_slug  = replace(var.domain, ".", "-")
  bucket_arn   = "arn:aws:s3:::${var.bucket_name}"
  ses_resource = var.s3_prefix != "" ? "${local.bucket_arn}/${trimprefix(var.s3_prefix, "/")}*" : "${local.bucket_arn}/*"
}

resource "aws_ses_domain_identity" "this" {
  domain = var.domain
}

resource "aws_ses_receipt_rule_set" "this" {
  rule_set_name = "${local.domain_slug}-inbound"
}

resource "aws_ses_active_receipt_rule_set" "this" {
  for_each      = var.activate_rule_set ? toset(["enabled"]) : toset([])
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
}
