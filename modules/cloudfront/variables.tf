# Variables for the cloudfront module.

variable "name" {
  description = "Logical name for the distribution; used to name all child resources."
  type        = string
}

variable "origin_domain_name" {
  description = "Domain name of the origin (S3 regional domain or custom hostname)."
  type        = string
}

variable "origin_type" {
  description = "Origin type: 's3' (uses OAC + sigv4) or 'custom' (uses HTTPS custom origin)."
  type        = string
  default     = "s3"

  validation {
    condition     = contains(["s3", "custom"], var.origin_type)
    error_message = "origin_type must be 's3' or 'custom'."
  }
}

variable "aliases" {
  description = "Custom domain aliases for the distribution (e.g. [\"example.com\"])."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of an existing ACM certificate in us-east-1. Required when aliases is non-empty and create_certificate is false."
  type        = string
  default     = null
}

variable "create_certificate" {
  description = "Create an ACM certificate for the first alias. Requires aliases to be non-empty."
  type        = bool
  default     = false
}

variable "cache_policy_id" {
  description = "CloudFront cache policy ID. Defaults to AWS managed CachingOptimized."
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
}

variable "function_associations" {
  description = "CloudFront function associations for the default cache behavior."
  type = list(object({
    event_type   = string
    function_arn = string
  }))
  default = []
}

variable "allowed_methods" {
  description = "HTTP methods allowed by the default cache behavior."
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "web_acl_id" {
  description = "ARN of a WAFv2 Web ACL to associate with the distribution. If null, no WAF is attached."
  type        = string
  default     = null
}

variable "comment" {
  description = "Comment for the CloudFront distribution."
  type        = string
  default     = null
}

variable "extra_origins" {
  description = "Additional origins beyond the primary origin."
  type = list(object({
    domain_name               = string
    origin_id                 = string
    origin_access_control_id  = optional(string)
    s3_origin_access_identity = optional(string)
    custom_origin_config = optional(object({
      http_port              = number
      https_port             = number
      origin_protocol_policy = string
      origin_ssl_protocols   = list(string)
    }))
  }))
  default = []
}

variable "ordered_cache_behaviors" {
  description = "Ordered cache behaviors appended after the default behavior."
  type = list(object({
    path_pattern             = string
    target_origin_id         = string
    viewer_protocol_policy   = string
    allowed_methods          = list(string)
    cached_methods           = list(string)
    compress                 = bool
    cache_policy_id          = string
    origin_request_policy_id = optional(string)
    trusted_key_groups       = optional(list(string))
  }))
  default = []
}

variable "custom_error_responses" {
  description = "Custom error responses for the distribution."
  type = list(object({
    error_code            = number
    response_code         = number
    response_page_path    = string
    error_caching_min_ttl = number
  }))
  default = []
}

variable "access_log_bucket" {
  description = "S3 bucket domain name for CloudFront access logs (e.g. my-logs-bucket.s3.amazonaws.com). Set to null to disable logging."
  type        = string
  default     = null
}

variable "access_log_prefix" {
  description = "Key prefix for CloudFront access log objects."
  type        = string
  default     = ""
}

variable "failover_origin_domain_name" {
  description = "Domain name of the failover origin. When set, an origin group is created with the primary origin as primary and this as the failover. Enables CKV_AWS_310 compliance."
  type        = string
  default     = null
}

variable "failover_status_codes" {
  description = "HTTP status codes that trigger failover to the secondary origin."
  type        = list(number)
  default     = [500, 502, 503, 504]
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "geo_restriction_type" {
  description = "Type of geo restriction: 'none', 'whitelist', or 'blacklist'."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "geo_restriction_type must be 'none', 'whitelist', or 'blacklist'."
  }
}

variable "geo_restriction_locations" {
  description = "List of ISO 3166-1 alpha-2 country codes for geo restriction. Required when geo_restriction_type is 'whitelist' or 'blacklist'."
  type        = list(string)
  default     = []
}
