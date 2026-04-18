variable "name" {
  description = "Base name for all resources in this composition."
  type        = string
  default     = "my-site"
}

variable "domain" {
  description = "Primary domain name for the CloudFront distribution and ACM certificate (e.g. example.com)."
  type        = string
  default     = "example.com"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    env     = "example"
    project = "wsht"
  }
}
