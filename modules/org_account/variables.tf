variable "account_name" {
  description = "Display name for the AWS Organizations account."
  type        = string
}

variable "email" {
  description = "Unique email address for the account root user."
  type        = string
}

variable "parent_id" {
  description = "Organizations OU or root ID to place the account in. Defaults to org root."
  type        = string
  default     = null
}

variable "iam_user_access_to_billing" {
  description = "Allow IAM users to access billing. ALLOW or DENY."
  type        = string
  default     = "DENY"
}

variable "sso_instance_arn" {
  description = "ARN of the IAM Identity Center instance."
  type        = string
}

variable "assignments" {
  description = "List of {principal_id, principal_type, permission_set_arn} to assign to this account."
  type = list(object({
    principal_id       = string
    principal_type     = string
    permission_set_arn = string
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the Organizations account resource."
  type        = map(string)
  default     = {}
}
