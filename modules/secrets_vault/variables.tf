variable "name" {
  description = "Override the derived resource-name base. Defaults to path_prefix with slashes replaced by dashes (e.g. \"appw/prod\" -> \"appw-prod\"). Names the reader role (\"<base>-secrets-reader\") and its inline policy (\"<base>-secrets-read\"). Leave null to derive it so the names can't drift from the prefix; set it only when you need a specific role name."
  type        = string
  default     = null
}

variable "path_prefix" {
  description = "Path prefix under which this app's secrets live. House convention is \"<app>/<env>\", e.g. \"appw/prod\" — app-first, so an app's secrets group together and an app-wide grant is a single \"<app>/*\" wildcard. The reader role is scoped to \"<path_prefix>/*\", so instantiate once per (app, env) — each (app, env) gets its own role and trusted principals, keeping prod secrets unreadable by a staging role. Drop the env segment (e.g. \"appw\") for single-account setups. No leading or trailing slash."
  type        = string

  validation {
    condition     = length(var.path_prefix) > 0 && !startswith(var.path_prefix, "/") && !endswith(var.path_prefix, "/")
    error_message = "path_prefix must be non-empty with no leading or trailing slash (e.g. \"appw/prod\")."
  }
}

variable "trusted_principals" {
  description = "ARNs allowed to assume the reader role — typically the app account root (\"arn:aws:iam::<app-acct>:root\") or specific app workload role ARNs."
  type        = list(string)

  validation {
    condition     = length(var.trusted_principals) > 0
    error_message = "trusted_principals must list at least one ARN."
  }
}

variable "external_id" {
  description = "If set, assuming the reader role requires this sts:ExternalId (confused-deputy mitigation). The consumer must pass the same value at AssumeRole time."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for the reader role. 3600–43200."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "secrets" {
  description = "Secret containers to create under path_prefix. Map key is the short name (full name becomes \"<path_prefix>/<key>\"). This module never manages secret *values* — only the empty containers — so plaintext never lands in Terraform state. Set values out-of-band with `aws secretsmanager put-secret-value`."
  type = map(object({
    description = optional(string)
  }))
  default = {}
}

variable "recovery_window_days" {
  description = "Days Secrets Manager retains a deleted secret before permanent deletion. 0 forces immediate deletion; otherwise 7–30."
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_days == 0 || (var.recovery_window_days >= 7 && var.recovery_window_days <= 30)
    error_message = "recovery_window_days must be 0 or between 7 and 30."
  }
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
