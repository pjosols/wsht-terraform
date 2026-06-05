variable "vector_bucket_name" {
  description = "Name of the S3 Vectors bucket."
  type        = string
}

variable "index_name" {
  description = "Name of the vector index within the bucket."
  type        = string
}

variable "dimension" {
  description = "Vector dimensionality (e.g. 1024 for Titan Text Embeddings v2). Immutable."
  type        = number
  default     = 1024
}

variable "distance_metric" {
  description = "Distance metric: 'cosine' or 'euclidean'. Immutable."
  type        = string
  default     = "cosine"
}

variable "data_type" {
  description = "Vector element data type. Immutable."
  type        = string
  default     = "float32"
}

variable "non_filterable_metadata_keys" {
  description = "Metadata keys stored but not filterable (e.g. the chunk text). Everything else is filterable, capped at 10 filterable keys per index."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN for the vector bucket. null = S3-managed (AES256)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
