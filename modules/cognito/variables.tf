variable "name" {
  description = "User pool name."
  type        = string
}

variable "callback_urls" {
  description = "Allowed OAuth callback URLs for the app client."
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "Allowed OAuth logout URLs for the app client."
  type        = list(string)
  default     = []
}

variable "explicit_auth_flows" {
  description = "List of explicit auth flows to enable on the app client."
  type        = list(string)
}

variable "access_token_validity" {
  description = "Access token validity in hours."
  type        = number
  default     = 1
  validation {
    condition     = var.access_token_validity > 0
    error_message = "access_token_validity must be > 0."
  }
}

variable "id_token_validity" {
  description = "ID token validity in hours."
  type        = number
  default     = 1
  validation {
    condition     = var.id_token_validity > 0
    error_message = "id_token_validity must be > 0."
  }
}

variable "refresh_token_validity" {
  description = "Refresh token validity in days."
  type        = number
  default     = 30
  validation {
    condition     = var.refresh_token_validity > 0
    error_message = "refresh_token_validity must be > 0."
  }
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
