output "reader_role_arn" {
  description = "ARN of the cross-account reader role. Pass this to modules/secrets_consumer (vault_role_arns) in the app account so its workload role can assume it."
  value       = aws_iam_role.reader.arn
}

output "reader_role_name" {
  description = "Name of the cross-account reader role."
  value       = aws_iam_role.reader.name
}

output "secret_arns" {
  description = "Map of short name => ARN for each created secret container (empty if no secrets were created here)."
  value       = { for k, s in aws_secretsmanager_secret.this : k => s.arn }
}

output "secret_arn_wildcard" {
  description = "The \"<path_prefix>/*\" ARN pattern the reader role is scoped to."
  value       = local.secret_arn_wildcard
}

output "path_prefix" {
  description = "The path prefix this app's secrets live under."
  value       = var.path_prefix
}
