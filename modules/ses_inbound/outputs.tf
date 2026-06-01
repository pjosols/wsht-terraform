output "verification_token" {
  description = "SES domain verification token. Add as a TXT DNS record at _amazonses.<domain>."
  value       = aws_ses_domain_identity.this.verification_token
}

output "receipt_rule_set_name" {
  description = "Name of the SES receipt rule set."
  value       = aws_ses_receipt_rule_set.this.rule_set_name
}

output "bucket_policy_json" {
  description = "IAM policy JSON granting SES permission to write to the configured bucket. Pass to the s3_bucket module's policy_json input."
  value = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSESPuts"
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = local.ses_resource
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
