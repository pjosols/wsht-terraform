output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_id" {
  description = "Name (ID) of the S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket (for CloudFront origins)."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_domain_name" {
  description = "Global domain name of the S3 bucket (for CloudFront logging config)."
  value       = aws_s3_bucket.this.bucket_domain_name
}
