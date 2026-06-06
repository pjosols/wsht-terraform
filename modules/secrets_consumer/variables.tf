variable "name" {
  description = "App/service name. Used to name the IAM policy (\"<name>-secrets-access\")."
  type        = string
}

variable "vault_role_arns" {
  description = "Reader role ARN(s) from the vault account (the reader_role_arn output of modules/secrets_vault) that the workload may assume."
  type        = list(string)

  validation {
    condition     = length(var.vault_role_arns) > 0
    error_message = "vault_role_arns must list at least one reader role ARN."
  }
}

variable "attach_to_role_names" {
  description = "Existing IAM role names to attach the generated policy to. Leave empty to attach it yourself using the policy_arn output."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
