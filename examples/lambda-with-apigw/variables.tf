variable "name" {
  description = "Base name for all resources in this composition."
  type        = string
  default     = "my-service"
}

variable "image_uri" {
  description = "ECR image URI to deploy to Lambda (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-service:latest)."
  type        = string
  default     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-service:latest"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    env     = "example"
    project = "wsht"
  }
}
