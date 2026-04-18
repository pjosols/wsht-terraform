variable "name" {
  description = "Lambda function name (e.g. 'page-generator'). Used in all resource names."
  type        = string
}

variable "image_uri" {
  description = "ECR image URI to deploy (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/repo:tag)."
  type        = string
}

variable "environment_variables" {
  description = "Environment variables to set on the Lambda function."
  type        = map(string)
  default     = {}
}

variable "iam_policy_json" {
  description = "IAM policy JSON string granting the Lambda permissions beyond logs and ECR pull."
  type        = string
  validation {
    condition     = can(jsondecode(var.iam_policy_json))
    error_message = "iam_policy_json must be valid JSON."
  }
}

variable "timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 30
  validation {
    condition     = var.timeout > 0
    error_message = "timeout must be > 0."
  }
}

variable "memory_size" {
  description = "Lambda memory in MB."
  type        = number
  default     = 256
  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240 MB."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 1
    error_message = "log_retention_days must be >= 1."
  }
}

variable "ecr_keep_image_count" {
  description = "Number of ECR images to retain via lifecycle policy."
  type        = number
  default     = 5
  validation {
    condition     = var.ecr_keep_image_count >= 1
    error_message = "ecr_keep_image_count must be >= 1."
  }
}

variable "vpc_config" {
  description = "Optional VPC configuration for the Lambda."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting Lambda environment variables, CloudWatch log group, and ECR repository."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "dead_letter_arn" {
  description = "ARN of SQS queue or SNS topic for Lambda dead-letter config. Prevents silent loss of failed async invocations."
  type        = string
  default     = null
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency limit for the Lambda. Null means unreserved (uses account pool)."
  type        = number
  default     = null
  validation {
    condition     = var.reserved_concurrent_executions == null || try(var.reserved_concurrent_executions >= 0, false)
    error_message = "reserved_concurrent_executions must be null or >= 0."
  }
}

variable "ephemeral_storage_mb" {
  description = "Ephemeral /tmp storage in MB (512–10240). Increase for video/image processing workloads."
  type        = number
  default     = 512
  validation {
    condition     = var.ephemeral_storage_mb >= 512 && var.ephemeral_storage_mb <= 10240
    error_message = "ephemeral_storage_mb must be between 512 and 10240 MB."
  }
}

variable "permissions_boundary_arn" {
  description = "IAM permissions boundary ARN to attach to the Lambda execution role. Enables org-level guardrails."
  type        = string
  default     = null
}
