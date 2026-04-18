# Outputs for the cloudfront module.

output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.this.arn
}

output "domain_name" {
  description = "CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "oac_id" {
  description = "Origin Access Control ID (S3 origins only; null for custom origins)."
  value       = var.origin_type == "s3" ? aws_cloudfront_origin_access_control.this["enabled"].id : null
}

output "acm_validation_records" {
  description = "ACM DNS validation records (only populated when create_certificate = true)."
  value = var.create_certificate ? [for o in aws_acm_certificate.this["enabled"].domain_validation_options : {
    name  = o.resource_record_name
    value = o.resource_record_value
  }] : []
}
