output "error_alarm_arn" {
  description = "ARN of the Lambda error count alarm."
  value       = aws_cloudwatch_metric_alarm.errors.arn
}

output "duration_alarm_arn" {
  description = "ARN of the Lambda duration alarm."
  value       = aws_cloudwatch_metric_alarm.duration.arn
}

output "throttles_alarm_arn" {
  description = "ARN of the Lambda throttles alarm."
  value       = aws_cloudwatch_metric_alarm.throttles.arn
}

output "schedule_rule_arn" {
  description = "ARN of the EventBridge schedule rule, if schedule_expression was set."
  value       = try(aws_cloudwatch_event_rule.schedule["enabled"].arn, "")
}
