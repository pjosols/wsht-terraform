/**
 * Provision CloudWatch alarms for Lambda errors, duration, and throttles.
 *
 * Creates CloudWatch metric alarms for Lambda function errors, duration (with
 * configurable threshold percentage), and throttles. Optionally creates EventBridge
 * scheduled rule for canary/health-check invocation.
 */

locals {
  duration_threshold_ms = var.lambda_timeout * 1000 * var.duration_threshold_pct / 100
  schedule_set          = var.schedule_expression != "" ? toset(["enabled"]) : toset([])
}

resource "aws_cloudwatch_metric_alarm" "errors" {
  alarm_name          = "${var.lambda_function_name}-errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = var.lambda_function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.error_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Triggers when Lambda errors exceed ${var.error_threshold} per 5 minutes"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "duration" {
  alarm_name          = "${var.lambda_function_name}-duration"
  namespace           = "AWS/Lambda"
  metric_name         = "Duration"
  dimensions          = { FunctionName = var.lambda_function_name }
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  threshold           = local.duration_threshold_ms
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Triggers when Lambda duration exceeds ${var.duration_threshold_pct}% of timeout (${local.duration_threshold_ms}ms) per 5 minutes"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "throttles" {
  alarm_name          = "${var.lambda_function_name}-throttles"
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  dimensions          = { FunctionName = var.lambda_function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Triggers when Lambda throttles occur per 5 minutes"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Optional scheduled invocation — creates EventBridge rule + target when
# schedule_expression is set. Useful for canary/health-check patterns.
resource "aws_cloudwatch_event_rule" "schedule" {
  for_each            = local.schedule_set
  name                = "${var.lambda_function_name}-monitoring-schedule"
  description         = "Scheduled monitoring invocation for ${var.lambda_function_name}"
  schedule_expression = var.schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "schedule" {
  for_each = local.schedule_set
  rule     = aws_cloudwatch_event_rule.schedule[each.key].name
  arn      = var.lambda_function_arn
}
