variable "name" {
  description = "Key name, used to form the KMS alias."
  type        = string
}

variable "alias_prefix" {
  description = "Optional prefix for the KMS alias. When set, the alias becomes alias/<prefix>-<name>. When empty, the alias is alias/<name>."
  type        = string
  default     = ""
}

variable "description" {
  description = "Human-readable description for the KMS key."
  type        = string
}

variable "service_principals" {
  description = "List of AWS service principals (e.g. 'logs.us-east-1.amazonaws.com') granted Encrypt/Decrypt/GenerateDataKey permissions."
  type        = list(string)
  default     = []
}

variable "additional_policy_statements" {
  description = "Optional list of additional IAM policy statement objects to merge into the key policy."
  type = list(object({
    sid           = optional(string)
    effect        = optional(string, "Allow")
    actions       = list(string)
    not_actions   = optional(list(string))
    resources     = optional(list(string), ["*"])
    not_resources = optional(list(string))
    principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })))
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })))
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
