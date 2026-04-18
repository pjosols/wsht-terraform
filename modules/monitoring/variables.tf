variable "lambda_function_name" {
  description = "Name of the Lambda function to monitor."
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function. Used as the EventBridge schedule target. Required when schedule_expression is set."
  type        = string
  default     = ""
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds. Used to compute the duration alarm threshold."
  type        = number
  validation {
    condition     = var.lambda_timeout > 0
    error_message = "lambda_timeout must be > 0."
  }
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic to send alarm notifications to."
  type        = string
}

variable "error_threshold" {
  description = "Number of Lambda errors per period that triggers the error alarm."
  type        = number
  default     = 1
  validation {
    condition     = var.error_threshold >= 1
    error_message = "error_threshold must be >= 1."
  }
}

variable "duration_threshold_pct" {
  description = "Percentage of lambda_timeout at which the duration alarm fires (0–100)."
  type        = number
  default     = 80

  validation {
    condition     = var.duration_threshold_pct >= 0 && var.duration_threshold_pct <= 100
    error_message = "duration_threshold_pct must be between 0 and 100."
  }
}

variable "schedule_expression" {
  description = "Optional EventBridge schedule expression (e.g. 'rate(5 minutes)') to periodically invoke the Lambda for scheduled monitoring. Leave empty to skip."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
