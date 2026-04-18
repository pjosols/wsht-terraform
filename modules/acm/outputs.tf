output "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "domain_validation_options" {
  description = "DNS validation records the caller must create with their DNS provider"
  value       = aws_acm_certificate.this.domain_validation_options
}
