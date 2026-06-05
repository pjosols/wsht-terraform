output "vector_bucket_name" {
  description = "Vector bucket name."
  value       = aws_s3vectors_vector_bucket.this.vector_bucket_name
}

output "vector_bucket_arn" {
  description = "Vector bucket ARN."
  value       = aws_s3vectors_vector_bucket.this.vector_bucket_arn
}

output "index_name" {
  description = "Vector index name."
  value       = aws_s3vectors_index.this.index_name
}

output "index_arn" {
  description = "Vector index ARN. Grant s3vectors:PutVectors/QueryVectors on this."
  value       = aws_s3vectors_index.this.index_arn
}
