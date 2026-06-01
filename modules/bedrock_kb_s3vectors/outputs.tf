output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID."
  value       = aws_bedrockagent_knowledge_base.this.id
}

output "knowledge_base_arn" {
  description = "Bedrock Knowledge Base ARN. Use to grant bedrock:IngestKnowledgeBaseDocuments to your compute role."
  value       = aws_bedrockagent_knowledge_base.this.arn
}

output "data_source_id" {
  description = "Knowledge Base data source ID. Required when calling IngestKnowledgeBaseDocuments."
  value       = aws_bedrockagent_data_source.this.data_source_id
}

output "vector_bucket_arn" {
  description = "ARN of the S3 Vectors bucket."
  value       = aws_s3vectors_vector_bucket.this.vector_bucket_arn
}
