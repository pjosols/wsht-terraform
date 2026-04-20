mock_provider "aws" {}

variables {
  project = "myapp"
}

run "plan_succeeds_with_required_vars" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.this.name == "myapp-tfstate-lock"
    error_message = "table name should default to <project>-tfstate-lock"
  }

  assert {
    condition     = aws_dynamodb_table.this.hash_key == "LockID"
    error_message = "hash_key must be LockID"
  }

  assert {
    condition     = aws_dynamodb_table.this.billing_mode == "PAY_PER_REQUEST"
    error_message = "billing_mode must be PAY_PER_REQUEST"
  }
}

run "bucket_name_defaults_to_project_tfstate" {
  command = plan

  assert {
    condition     = output.bucket_name == "myapp-tfstate"
    error_message = "bucket_name should default to <project>-tfstate"
  }
}

run "table_name_defaults_to_project_tfstate_lock" {
  command = plan

  assert {
    condition     = output.table_name == "myapp-tfstate-lock"
    error_message = "table_name should default to <project>-tfstate-lock"
  }
}

run "bucket_name_override" {
  command = plan

  variables {
    bucket_name = "custom-bucket"
  }

  assert {
    condition     = output.bucket_name == "custom-bucket"
    error_message = "bucket_name override not respected"
  }
}

run "table_name_override" {
  command = plan

  variables {
    table_name = "custom-lock"
  }

  assert {
    condition     = output.table_name == "custom-lock"
    error_message = "table_name override not respected"
  }
}

run "backend_config_key_uses_project" {
  command = plan

  assert {
    condition     = output.backend_config["key"] == "myapp/terraform.tfstate"
    error_message = "backend_config key must be <project>/terraform.tfstate"
  }

  assert {
    condition     = output.backend_config["encrypt"] == true
    error_message = "backend_config encrypt must be true"
  }

  assert {
    condition     = output.backend_config["bucket"] == "myapp-tfstate"
    error_message = "backend_config bucket must match bucket_name"
  }

  assert {
    condition     = output.backend_config["dynamodb_table"] == "myapp-tfstate-lock"
    error_message = "backend_config dynamodb_table must match table_name"
  }
}

run "pitr_enabled" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.this.point_in_time_recovery[0].enabled == true
    error_message = "point-in-time recovery must be enabled"
  }
}

run "kms_sse_applied_when_key_provided" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  }

  assert {
    condition     = length(aws_dynamodb_table.this.server_side_encryption) == 1
    error_message = "SSE block must be present when kms_key_arn is provided"
  }

  assert {
    condition     = aws_dynamodb_table.this.server_side_encryption[0].kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    error_message = "SSE kms_key_arn must match the provided key"
  }
}

run "no_sse_block_without_kms_key" {
  command = plan

  assert {
    condition     = length(aws_dynamodb_table.this.server_side_encryption) == 0
    error_message = "SSE block must be absent when kms_key_arn is null"
  }
}

run "tags_applied_to_dynamodb" {
  command = plan

  variables {
    tags = { env = "test", project = "myapp" }
  }

  assert {
    condition     = aws_dynamodb_table.this.tags["env"] == "test"
    error_message = "tags not applied to DynamoDB table"
  }
}
