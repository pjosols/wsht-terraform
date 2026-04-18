variable "name" {
  description = "API name. Used in resource names and log group path."
  type        = string
}

variable "description" {
  description = "API description."
  type        = string
  default     = ""
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function to integrate with."
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name for the invoke permission."
  type        = string
}

variable "routes" {
  description = "List of routes to create. Each route has method, path, authorizer (NONE or a key from authorizer_configs), and optional per-route throttle overrides."
  type = list(object({
    method                 = string
    path                   = string
    authorizer             = optional(string, "NONE")
    throttling_rate_limit  = optional(number)
    throttling_burst_limit = optional(number)
  }))
}

variable "authorizer_configs" {
  description = "Map of named authorizer configurations. Routes reference authorizers by key. type must be JWT or REQUEST."
  type = map(object({
    type             = string
    name             = string
    identity_sources = list(string)
    jwt = optional(object({
      audience = list(string)
      issuer   = string
    }))
    authorizer_uri          = optional(string)
    payload_format_version  = optional(string, "2.0")
    enable_simple_responses = optional(bool, true)
    result_ttl_seconds      = optional(number, 0)
  }))
  default = {}
}

variable "extra_lambda_permissions" {
  description = "Map of extra Lambda invoke permissions to create (e.g. for REQUEST authorizer Lambdas). Key is statement_id suffix, value is function_name."
  type        = map(string)
  default     = {}
}

variable "cors_config" {
  description = "Optional CORS configuration. Disabled by default."
  type = object({
    allow_origins     = list(string)
    allow_methods     = list(string)
    allow_headers     = list(string)
    expose_headers    = optional(list(string), [])
    max_age           = optional(number, 300)
    allow_credentials = optional(bool, false)
  })
  default = null
}

variable "throttling_burst_limit" {
  description = "Default route throttling burst limit."
  type        = number
  default     = 100
  validation {
    condition     = var.throttling_burst_limit > 0
    error_message = "throttling_burst_limit must be > 0."
  }
}

variable "throttling_rate_limit" {
  description = "Default route throttling rate limit (requests per second)."
  type        = number
  default     = 50
  validation {
    condition     = var.throttling_rate_limit > 0
    error_message = "throttling_rate_limit must be > 0."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
  default     = 365
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting the access log group."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
