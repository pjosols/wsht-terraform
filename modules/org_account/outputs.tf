output "account_id" {
  description = "The AWS account ID of the created account."
  value       = aws_organizations_account.this.id
}

output "account_arn" {
  description = "The ARN of the created account."
  value       = aws_organizations_account.this.arn
}
