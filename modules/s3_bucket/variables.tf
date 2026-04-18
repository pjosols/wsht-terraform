variable "name" {
  description = "S3 bucket name."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption. If null, AES256 is used."
  type        = string
  default     = null
}

variable "policy_json" {
  description = "Bucket policy JSON string. If null, no bucket policy is created."
  type        = string
  default     = null

  validation {
    condition     = var.policy_json == null || can(jsondecode(var.policy_json))
    error_message = "policy_json must be valid JSON or null."
  }

  validation {
    condition     = var.policy_json == null || can(jsondecode(var.policy_json).Statement)
    error_message = "policy_json must contain a top-level 'Statement' key."
  }
}

variable "cors_rules" {
  description = "List of CORS rules. If null, no CORS configuration is created. allowed_headers defaults to [\"*\"] (all headers allowed); set explicitly to restrict. max_age_seconds defaults to 3600; set to 0 to disable preflight caching."
  type = list(object({
    allowed_methods = list(string)
    allowed_origins = list(string)
    allowed_headers = optional(list(string), ["*"])
    max_age_seconds = optional(number, 3600)
  }))
  default = null
}

variable "accelerate" {
  description = "Enable S3 Transfer Acceleration."
  type        = bool
  default     = false
}

variable "notification_config" {
  description = "S3 bucket notification configuration for Lambda triggers. If null, no notification is created."
  type = object({
    lambda_functions = list(object({
      lambda_function_arn = string
      events              = list(string)
      filter_prefix       = optional(string, "")
      filter_suffix       = optional(string, "")
    }))
  })
  default = null
}

variable "force_destroy" {
  description = "Allow Terraform to destroy the bucket even if it contains objects."
  type        = bool
  default     = false
}

variable "object_ownership" {
  description = "S3 object ownership setting. If null, no ownership controls resource is created."
  type        = string
  default     = null
}

variable "logging_bucket_id" {
  description = "ID of the S3 bucket to receive access logs. If null, logging is not enabled."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
