variable "name" {
  description = "Base name for all resources (vector bucket, index, KB, IAM role)."
  type        = string
}

variable "embedding_model_arn" {
  description = "ARN of the Bedrock foundation model used to generate embeddings (e.g. cohere.embed-multilingual-v3)."
  type        = string
}

variable "vector_dimension" {
  description = "Dimension of the embedding vectors. Must match the embedding model output (e.g. 1024 for Cohere Embed v3)."
  type        = number
}

variable "non_filterable_metadata_keys" {
  description = "Metadata keys stored for display only — excluded from vector index filtering. All other metadata keys are filterable."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
