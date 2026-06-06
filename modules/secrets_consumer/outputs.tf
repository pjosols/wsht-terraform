output "policy_arn" {
  description = "ARN of the IAM policy granting sts:AssumeRole on the vault reader role(s). Attach to your workload role."
  value       = aws_iam_policy.this.arn
}

output "policy_name" {
  description = "Name of the generated IAM policy."
  value       = aws_iam_policy.this.name
}

output "policy_json" {
  description = "The IAM policy document (JSON) granting sts:AssumeRole on the vault reader role(s)."
  value       = local.policy_json
}
