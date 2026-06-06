variable "name" {
  description = "Logical name; used to name the instance, role, SG, and profile."
  type        = string
}

variable "vpc_id" {
  description = "VPC to place the instance and security group in."
  type        = string
}

variable "subnet_id" {
  description = "Public subnet for the instance (it gets a public IP for internet egress — no NAT)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type. Default is a small Graviton burstable; the workload is I/O-bound."
  type        = string
  default     = "t4g.micro"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB (gp3)."
  type        = number
  default     = 20
}

variable "additional_iam_policy_json" {
  description = "App-specific IAM policy JSON attached to the instance role (e.g. S3 Vectors, DynamoDB, Bedrock). Null for none."
  type        = string
  default     = null
}

variable "readable_ssm_parameter_arns" {
  description = "SSM parameter ARNs the instance may read (e.g. the Caddy Cloudflare DNS token). SecureStrings also get kms:Decrypt."
  type        = list(string)
  default     = []
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs the instance may pull. Empty = all repositories in the account."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
