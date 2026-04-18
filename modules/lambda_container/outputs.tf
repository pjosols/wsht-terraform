output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function (for API Gateway integrations)."
  value       = aws_lambda_function.this.invoke_arn
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "role_arn" {
  description = "ARN of the Lambda IAM role."
  value       = aws_iam_role.this.arn
}

output "role_id" {
  description = "ID (name) of the Lambda IAM role, for attaching additional inline policies."
  value       = aws_iam_role.this.id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository."
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.name
}
