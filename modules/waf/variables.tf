variable "name" {
  description = "Name for the Web ACL and associated resources."
  type        = string
}

variable "rate_limit" {
  description = "Maximum requests per 5-minute window before rate limiting kicks in."
  type        = number
  default     = 1000

  validation {
    condition     = var.rate_limit > 0
    error_message = "rate_limit must be > 0."
  }
}

variable "additional_managed_rules" {
  description = "Optional list of extra managed rule group objects to add. Each object: { name, vendor_name, priority, metric_suffix, version (optional) }."
  type = list(object({
    name          = string
    vendor_name   = string
    priority      = number
    metric_suffix = string
    version       = optional(string, "")
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
