mock_provider "aws" {}

variables {
  name = "test-bucket"
}

# Plan succeeds with required variables only
run "plan_succeeds_with_required_vars" {
  command = plan
}

# Public access is blocked by default
run "public_access_blocked" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "block_public_acls must be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_policy == true
    error_message = "block_public_policy must be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.ignore_public_acls == true
    error_message = "ignore_public_acls must be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.restrict_public_buckets == true
    error_message = "restrict_public_buckets must be true"
  }
}

# Versioning is enabled by default
run "versioning_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "versioning must be Enabled"
  }
}

# Default encryption is AES256 when no KMS key provided
run "default_encryption_aes256" {
  command = plan

  assert {
    condition     = tolist(aws_s3_bucket_server_side_encryption_configuration.this.rule)[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "default SSE algorithm must be AES256"
  }
}

# KMS encryption used when kms_key_arn is provided
run "kms_encryption_when_key_provided" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
  }

  assert {
    condition     = tolist(aws_s3_bucket_server_side_encryption_configuration.this.rule)[0].apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "SSE algorithm must be aws:kms when kms_key_arn is set"
  }
}

# SSL deny policy is always applied
run "ssl_deny_policy_applied" {
  command = plan

  assert {
    condition     = output.bucket_policy_document != null
    error_message = "bucket policy document must not be null"
  }
}

# Default policy (no policy_json) contains DenyNonSSL statement
run "default_policy_contains_ssl_deny" {
  command = plan

  assert {
    condition     = can(jsondecode(output.bucket_policy_document).Statement)
    error_message = "default policy must have a Statement key"
  }

  assert {
    condition = anytrue([
      for s in jsondecode(output.bucket_policy_document).Statement : s.Sid == "DenyNonSSL"
    ])
    error_message = "default policy must contain DenyNonSSL statement"
  }
}

# Custom policy_json has DenyNonSSL merged in alongside caller's statements
run "custom_policy_merges_ssl_deny" {
  command = plan

  variables {
    policy_json = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid       = "AllowCloudFrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::test-bucket/*"
      }]
    })
  }

  assert {
    condition = anytrue([
      for s in jsondecode(output.bucket_policy_document).Statement : s.Sid == "DenyNonSSL"
    ])
    error_message = "merged policy must contain DenyNonSSL statement"
  }

  assert {
    condition = anytrue([
      for s in jsondecode(output.bucket_policy_document).Statement : s.Sid == "AllowCloudFrontOAC"
    ])
    error_message = "merged policy must preserve caller's Statement entries"
  }

  assert {
    condition     = length(jsondecode(output.bucket_policy_document).Statement) == 2
    error_message = "merged policy must have exactly 2 statements (caller + DenyNonSSL)"
  }
}

# DenyNonSSL condition targets aws:SecureTransport = false
run "ssl_deny_condition_correct" {
  command = plan

  assert {
    condition = anytrue([
      for s in jsondecode(output.bucket_policy_document).Statement :
      try(s.Condition.Bool["aws:SecureTransport"] == "false", false)
      if s.Sid == "DenyNonSSL"
    ])
    error_message = "DenyNonSSL must deny when aws:SecureTransport is false"
  }
}

# policy_json validation rejects invalid JSON
run "policy_json_rejects_invalid_json" {
  command = plan

  variables {
    policy_json = "not-valid-json"
  }

  expect_failures = [var.policy_json]
}

# policy_json validation rejects JSON without Statement key
run "policy_json_rejects_missing_statement" {
  command = plan

  variables {
    policy_json = "{\"Version\":\"2012-10-17\"}"
  }

  expect_failures = [var.policy_json]
}

# Logging resource not created when logging_bucket_id is null
run "logging_not_created_by_default" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_logging.this) == 0
    error_message = "logging resource must not be created when logging_bucket_id is null"
  }
}

# Logging resource created when logging_bucket_id is set
run "logging_created_when_configured" {
  command = plan

  variables {
    logging_bucket_id = "my-log-bucket"
  }

  assert {
    condition     = length(aws_s3_bucket_logging.this) == 1
    error_message = "logging resource must be created when logging_bucket_id is set"
  }
}

# CORS not created by default
run "cors_not_created_by_default" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_cors_configuration.this) == 0
    error_message = "CORS resource must not be created when cors_rules is null"
  }
}

# Acceleration not enabled by default
run "acceleration_not_enabled_by_default" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_accelerate_configuration.this) == 0
    error_message = "acceleration resource must not be created when accelerate is false"
  }
}

# prevent_destroy lifecycle is set on the primary bucket resource
# Regression: force_destroy must default to false (belt-and-suspenders with prevent_destroy)
run "force_destroy_defaults_false" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "force_destroy must default to false"
  }
}

# Regression: conditional resources use for_each (keyed "enabled"), not count (indexed 0)
# If count were used, the key would be numeric and length() would still pass but
# the resource address would differ — assert the "enabled" key exists directly.
run "logging_for_each_key" {
  command = plan

  variables {
    logging_bucket_id = "my-log-bucket"
  }

  assert {
    condition     = contains(keys(aws_s3_bucket_logging.this), "enabled")
    error_message = "logging must use for_each key 'enabled', not count index"
  }
}

run "cors_for_each_key" {
  command = plan

  variables {
    cors_rules = [{ allowed_methods = ["GET"], allowed_origins = ["https://example.com"] }]
  }

  assert {
    condition     = contains(keys(aws_s3_bucket_cors_configuration.this), "enabled")
    error_message = "cors_configuration must use for_each key 'enabled', not count index"
  }
}

run "accelerate_for_each_key" {
  command = plan

  variables {
    accelerate = true
  }

  assert {
    condition     = contains(keys(aws_s3_bucket_accelerate_configuration.this), "enabled")
    error_message = "accelerate_configuration must use for_each key 'enabled', not count index"
  }
}

# ownership_controls not created by default
run "ownership_controls_not_created_by_default" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_ownership_controls.this) == 0
    error_message = "ownership_controls must not be created when object_ownership is null"
  }
}

run "ownership_controls_for_each_key" {
  command = plan

  variables {
    object_ownership = "BucketOwnerEnforced"
  }

  assert {
    condition     = contains(keys(aws_s3_bucket_ownership_controls.this), "enabled")
    error_message = "ownership_controls must use for_each key 'enabled', not count index"
  }
}

# notification not created by default
run "notification_not_created_by_default" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_notification.this) == 0
    error_message = "notification must not be created when notification_config is null"
  }
}

run "notification_for_each_key" {
  command = plan

  variables {
    notification_config = {
      lambda_functions = [{
        lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:test"
        events              = ["s3:ObjectCreated:*"]
      }]
    }
  }

  assert {
    condition     = contains(keys(aws_s3_bucket_notification.this), "enabled")
    error_message = "notification must use for_each key 'enabled', not count index"
  }
}

# Regression: DenyNonSSL must cover both the bucket ARN and the wildcard (/*) resource.
# A statement scoped only to the bucket ARN would not block object-level non-SSL requests.
run "ssl_deny_covers_bucket_and_objects" {
  command = plan

  assert {
    condition = anytrue([
      for s in jsondecode(output.bucket_policy_document).Statement :
      try(
        length([for r in s.Resource : r if endswith(r, "/*")]) > 0 &&
        length([for r in s.Resource : r if !endswith(r, "/*")]) > 0,
        false
      )
      if s.Sid == "DenyNonSSL"
    ])
    error_message = "DenyNonSSL must include both the bucket ARN and the wildcard object ARN (/*)"
  }
}

# Regression: merging a custom policy must preserve the caller's Version field.
# jsondecode→merge→jsonencode would drop Version if the merge only updated Statement.
run "custom_policy_preserves_version" {
  command = plan

  variables {
    policy_json = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid       = "AllowRead"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::test-bucket/*"
      }]
    })
  }

  assert {
    condition     = jsondecode(output.bucket_policy_document).Version == "2012-10-17"
    error_message = "merged policy must preserve the Version field from the caller's policy"
  }
}
