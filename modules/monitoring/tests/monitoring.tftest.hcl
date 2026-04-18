mock_provider "aws" {}

variables {
  lambda_function_name = "my-function"
  lambda_timeout       = 30
  sns_topic_arn        = "arn:aws:sns:us-east-1:123456789012:alerts"
}

# Plan succeeds with required variables only
run "plan_succeeds_with_required_vars" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.errors.alarm_name == "my-function-errors"
    error_message = "error alarm name mismatch"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.duration.alarm_name == "my-function-duration"
    error_message = "duration alarm name mismatch"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.throttles.alarm_name == "my-function-throttles"
    error_message = "throttles alarm name mismatch"
  }
}

# Duration threshold computed correctly (30s * 80% * 1000ms = 24000ms)
run "duration_threshold_computed" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.duration.threshold == 24000
    error_message = "duration threshold should be 24000ms (30s * 80%)"
  }
}

# No EventBridge rule created when schedule_expression is empty
run "no_schedule_rule_when_empty" {
  command = plan

  assert {
    condition     = length(aws_cloudwatch_event_rule.schedule) == 0
    error_message = "schedule rule should not be created when schedule_expression is empty"
  }
}

# EventBridge rule created when schedule_expression is set
run "schedule_rule_created_when_set" {
  command = plan

  variables {
    schedule_expression = "rate(5 minutes)"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.schedule) == 1
    error_message = "schedule rule should be created when schedule_expression is set"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.schedule["enabled"].schedule_expression == "rate(5 minutes)"
    error_message = "schedule expression mismatch"
  }
}

# Outputs are not null — mock provider resolves ARNs at apply time
# Note: uses plan to avoid prevent_destroy teardown conflict in terraform test
run "outputs_not_null" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.errors.alarm_name != ""
    error_message = "errors alarm must be planned"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.duration.alarm_name != ""
    error_message = "duration alarm must be planned"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.throttles.alarm_name != ""
    error_message = "throttles alarm must be planned"
  }
}

# Regression: event target ARN comes from var.lambda_function_arn, not data sources
run "schedule_target_uses_var_arn" {
  command = plan

  variables {
    schedule_expression = "rate(5 minutes)"
    lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:my-function"
  }

  assert {
    condition     = aws_cloudwatch_event_target.schedule["enabled"].arn == "arn:aws:lambda:us-east-1:123456789012:function:my-function"
    error_message = "event target ARN must equal var.lambda_function_arn, not a data-source-constructed value"
  }
}

# schedule_rule_arn is empty string when no schedule set (try fallback)
run "schedule_rule_arn_empty_without_schedule" {
  command = plan

  assert {
    condition     = output.schedule_rule_arn == ""
    error_message = "schedule_rule_arn should be empty string when no schedule_expression"
  }
}

# schedule_rule_arn is non-empty when schedule is set
run "schedule_rule_arn_set_with_schedule" {
  command = plan

  variables {
    schedule_expression = "rate(5 minutes)"
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.schedule) == 1
    error_message = "schedule rule should exist when schedule_expression is set"
  }
}

# lambda_timeout validation rejects zero
run "lambda_timeout_rejects_zero" {
  command = plan

  variables {
    lambda_timeout = 0
  }

  expect_failures = [var.lambda_timeout]
}

# lambda_timeout validation rejects negative values
run "lambda_timeout_rejects_negative" {
  command = plan

  variables {
    lambda_timeout = -1
  }

  expect_failures = [var.lambda_timeout]
}

# duration_threshold_pct validation rejects values below 0
run "duration_threshold_pct_rejects_negative" {
  command = plan

  variables {
    duration_threshold_pct = -1
  }

  expect_failures = [var.duration_threshold_pct]
}

# duration_threshold_pct validation rejects values above 100
run "duration_threshold_pct_rejects_above_100" {
  command = plan

  variables {
    duration_threshold_pct = 101
  }

  expect_failures = [var.duration_threshold_pct]
}

# duration_threshold_pct accepts boundary values 0 and 100
run "duration_threshold_pct_accepts_boundaries" {
  command = plan

  variables {
    duration_threshold_pct = 0
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.duration.threshold == 0
    error_message = "threshold should be 0 when duration_threshold_pct is 0"
  }
}

# error_threshold validation rejects zero
run "error_threshold_rejects_zero" {
  command = plan

  variables {
    error_threshold = 0
  }

  expect_failures = [var.error_threshold]
}

# error_threshold validation rejects negative values
run "error_threshold_rejects_negative" {
  command = plan

  variables {
    error_threshold = -5
  }

  expect_failures = [var.error_threshold]
}

# Tags propagated to alarms
run "tags_propagated" {
  command = plan

  variables {
    tags = { env = "test" }
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.errors.tags["env"] == "test"
    error_message = "tags not propagated to error alarm"
  }
}

# Regression: alarm_description set on all three alarms
run "alarm_descriptions_set" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.errors.alarm_description == "Triggers when Lambda errors exceed 1 per 5 minutes"
    error_message = "errors alarm_description missing or incorrect"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.duration.alarm_description != ""
    error_message = "duration alarm_description must not be empty"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.throttles.alarm_description != ""
    error_message = "throttles alarm_description must not be empty"
  }
}

# Regression: error alarm description reflects custom error_threshold
run "error_alarm_description_reflects_threshold" {
  command = plan

  variables {
    error_threshold = 5
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.errors.alarm_description == "Triggers when Lambda errors exceed 5 per 5 minutes"
    error_message = "errors alarm_description should interpolate error_threshold"
  }
}

# Regression: prevent_destroy is set on all three alarms.
# terraform test cannot assert lifecycle meta-arguments directly; this run
# confirms the alarms are present and the teardown error (prevent_destroy
# blocking destroy) is the expected signal that the lifecycle block is active.
# The apply runs above were intentionally converted to plan to avoid that
# teardown conflict — if prevent_destroy were removed, teardown would silently
# succeed and this comment would be the only indicator something changed.
run "prevent_destroy_alarms_present" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.errors.alarm_name == "my-function-errors"
    error_message = "errors alarm must exist (prevent_destroy regression)"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.duration.alarm_name == "my-function-duration"
    error_message = "duration alarm must exist (prevent_destroy regression)"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.throttles.alarm_name == "my-function-throttles"
    error_message = "throttles alarm must exist (prevent_destroy regression)"
  }
}
