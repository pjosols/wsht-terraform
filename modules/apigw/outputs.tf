output "api_id" {
  description = "ID of the API Gateway HTTP API."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Default endpoint URL of the API Gateway HTTP API."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "stage_id" {
  description = "ID of the $default stage."
  value       = aws_apigatewayv2_stage.default.id
}

output "execution_arn" {
  description = "Execution ARN of the API Gateway HTTP API (for Lambda permissions)."
  value       = aws_apigatewayv2_api.this.execution_arn
}
