mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/test-fn-lambda"
    }
  }
}

variables {
  name            = "test-fn"
  image_uri       = "123456789012.dkr.ecr.us-east-1.amazonaws.com/test-fn:latest"
  iam_policy_json = jsonencode({ Version = "2012-10-17", Statement = [] })
}

# Plan succeeds with required variables only
run "plan_succeeds_with_required_vars" {
  command = plan
}

# function_name output equals var.name
run "function_name_equals_var_name" {
  command = plan

  assert {
    condition     = aws_lambda_function.this.function_name == "test-fn"
    error_message = "function_name must equal var.name"
  }
}

# log_group_name output matches expected path
run "log_group_name_correct" {
  command = plan

  assert {
    condition     = aws_cloudwatch_log_group.this.name == "/aws/lambda/test-fn"
    error_message = "log_group name must be /aws/lambda/<name>"
  }
}

# ECR encryption is KMS
run "ecr_uses_kms_encryption" {
  command = plan

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].encryption_type == "KMS"
    error_message = "ECR repository must use KMS encryption"
  }
}

# ECR image tags are immutable
run "ecr_image_tags_immutable" {
  command = plan

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "IMMUTABLE"
    error_message = "ECR image tags must be IMMUTABLE"
  }
}

# Lambda uses arm64 architecture
run "lambda_arm64_architecture" {
  command = plan

  assert {
    condition     = contains(aws_lambda_function.this.architectures, "arm64")
    error_message = "Lambda must use arm64 architecture"
  }
}

# Lambda uses Image package type
run "lambda_image_package_type" {
  command = plan

  assert {
    condition     = aws_lambda_function.this.package_type == "Image"
    error_message = "Lambda must use Image package type"
  }
}

# X-Ray tracing is Active
run "lambda_xray_tracing_active" {
  command = plan

  assert {
    condition     = aws_lambda_function.this.tracing_config[0].mode == "Active"
    error_message = "Lambda X-Ray tracing must be Active"
  }
}

# log_retention_days defaults to 30
run "log_retention_days_default_is_30" {
  command = plan

  assert {
    condition     = aws_cloudwatch_log_group.this.retention_in_days == 30
    error_message = "log_retention_days default must be 30"
  }
}

# log_retention_days rejects 0 (never-expire)
run "log_retention_days_rejects_zero" {
  command = plan

  variables {
    log_retention_days = 0
  }

  expect_failures = [var.log_retention_days]
}

# log_retention_days accepts 1 (minimum)
run "log_retention_days_accepts_one" {
  command = plan

  variables {
    log_retention_days = 1
  }
}

# log_retention_days accepts values below 365 (regression: old >= 365 guard removed)
run "log_retention_days_accepts_30" {
  command = plan

  variables {
    log_retention_days = 30
  }
}

# ecr_keep_image_count rejects zero
run "ecr_keep_image_count_rejects_zero" {
  command = plan

  variables {
    ecr_keep_image_count = 0
  }

  expect_failures = [var.ecr_keep_image_count]
}

# ecr_keep_image_count rejects negative values
run "ecr_keep_image_count_rejects_negative" {
  command = plan

  variables {
    ecr_keep_image_count = -1
  }

  expect_failures = [var.ecr_keep_image_count]
}

# ecr_keep_image_count accepts 1 (boundary)
run "ecr_keep_image_count_accepts_one" {
  command = plan

  variables {
    ecr_keep_image_count = 1
  }
}

# ECR lifecycle policy keeps the configured image count
run "ecr_lifecycle_policy_keep_count" {
  command = plan

  variables {
    ecr_keep_image_count = 3
  }

  assert {
    condition     = jsondecode(aws_ecr_lifecycle_policy.this.policy).rules[0].selection.countNumber == 3
    error_message = "ECR lifecycle policy countNumber must match ecr_keep_image_count"
  }

  assert {
    condition     = jsondecode(aws_ecr_lifecycle_policy.this.policy).rules[0].action.type == "expire"
    error_message = "ECR lifecycle policy action must be expire"
  }
}

# KMS key is applied to the CloudWatch log group
run "log_group_kms_encryption" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/test-key"
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/test-key"
    error_message = "CloudWatch log group must use the supplied KMS key"
  }
}

# dead_letter_config is set when dead_letter_arn is provided
run "dead_letter_config_set" {
  command = plan

  variables {
    dead_letter_arn = "arn:aws:sqs:us-east-1:123456789012:test-dlq"
  }

  assert {
    condition     = aws_lambda_function.this.dead_letter_config[0].target_arn == "arn:aws:sqs:us-east-1:123456789012:test-dlq"
    error_message = "dead_letter_config target_arn must match dead_letter_arn"
  }
}

# dead_letter_config is absent when dead_letter_arn is null
run "dead_letter_config_absent_by_default" {
  command = plan

  assert {
    condition     = length(aws_lambda_function.this.dead_letter_config) == 0
    error_message = "dead_letter_config must be absent when dead_letter_arn is null"
  }
}

# VPC config is applied when vpc_config is provided
run "vpc_config_applied" {
  command = plan

  variables {
    vpc_config = {
      subnet_ids         = ["subnet-aaa", "subnet-bbb"]
      security_group_ids = ["sg-111"]
    }
  }

  assert {
    condition     = length(aws_lambda_function.this.vpc_config[0].subnet_ids) == 2
    error_message = "vpc_config must set subnet_ids"
  }
}

# VPC config is absent by default
run "vpc_config_absent_by_default" {
  command = plan

  assert {
    condition     = length(aws_lambda_function.this.vpc_config) == 0
    error_message = "vpc_config must be absent when not provided"
  }
}

# iam_policy_json validation rejects invalid JSON
run "iam_policy_json_rejects_invalid_json" {
  command = plan

  variables {
    iam_policy_json = "not-valid-json"
  }

  expect_failures = [var.iam_policy_json]
}

# iam_policy_json accepts valid JSON
run "iam_policy_json_accepts_valid_json" {
  command = plan

  variables {
    iam_policy_json = jsonencode({ Version = "2012-10-17", Statement = [] })
  }
}

# timeout validation rejects zero
run "timeout_rejects_zero" {
  command = plan

  variables {
    timeout = 0
  }

  expect_failures = [var.timeout]
}

# timeout validation rejects negative values
run "timeout_rejects_negative" {
  command = plan

  variables {
    timeout = -1
  }

  expect_failures = [var.timeout]
}

# timeout accepts positive value
run "timeout_accepts_positive" {
  command = plan

  variables {
    timeout = 60
  }
}

# reserved_concurrent_executions validation rejects negative values
run "reserved_concurrent_executions_rejects_negative" {
  command = plan

  variables {
    reserved_concurrent_executions = -1
  }

  expect_failures = [var.reserved_concurrent_executions]
}

# reserved_concurrent_executions accepts zero
run "reserved_concurrent_executions_accepts_zero" {
  command = plan

  variables {
    reserved_concurrent_executions = 0
  }
}

# reserved_concurrent_executions accepts null (default)
run "reserved_concurrent_executions_accepts_null" {
  command = plan

  variables {
    reserved_concurrent_executions = null
  }
}

# memory_size validation rejects values below 128
run "memory_size_rejects_below_128" {
  command = plan

  variables {
    memory_size = 64
  }

  expect_failures = [var.memory_size]
}

# memory_size validation rejects values above 10240
run "memory_size_rejects_above_10240" {
  command = plan

  variables {
    memory_size = 10241
  }

  expect_failures = [var.memory_size]
}

# memory_size accepts boundary values
run "memory_size_accepts_boundaries" {
  command = plan

  variables {
    memory_size = 128
  }
}

# ephemeral_storage_mb rejects values below 512
run "ephemeral_storage_mb_rejects_below_512" {
  command = plan

  variables {
    ephemeral_storage_mb = 511
  }

  expect_failures = [var.ephemeral_storage_mb]
}

# ephemeral_storage_mb rejects values above 10240
run "ephemeral_storage_mb_rejects_above_10240" {
  command = plan

  variables {
    ephemeral_storage_mb = 10241
  }

  expect_failures = [var.ephemeral_storage_mb]
}

# ephemeral_storage_mb accepts boundary values
run "ephemeral_storage_mb_accepts_boundaries" {
  command = plan

  variables {
    ephemeral_storage_mb = 512
  }
}

run "ephemeral_storage_mb_accepts_max" {
  command = plan

  variables {
    ephemeral_storage_mb = 10240
  }
}
