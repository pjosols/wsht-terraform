variable "project" {
  description = "Project name. Used to derive bucket name (<project>-tfstate) and table name (<project>-tfstate-lock)."
  type        = string
}

variable "bucket_name" {
  description = "Override the default bucket name. Defaults to '<project>-tfstate'."
  type        = string
  default     = null
}

variable "table_name" {
  description = "Override the default DynamoDB table name. Defaults to '<project>-tfstate-lock'."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for S3 and DynamoDB encryption. If null, AES256/AWS-managed keys are used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
