variable "domain" {
  description = "Domain to configure SES inbound receipt for (e.g. wsht.me)."
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket where inbound emails will be stored."
  type        = string
}

variable "s3_prefix" {
  description = "S3 key prefix prepended to stored email objects. Must include a trailing slash if non-empty (e.g. 'emails/'). Set to empty string to store at bucket root."
  type        = string
  default     = "emails/"

  validation {
    condition     = var.s3_prefix == "" || endswith(var.s3_prefix, "/")
    error_message = "s3_prefix must be empty or end with a trailing slash."
  }
}

variable "activate_rule_set" {
  description = "Set this receipt rule set as the active rule set for the region. Only one rule set can be active per region per account."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
