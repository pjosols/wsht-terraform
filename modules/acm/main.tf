/**
 * Provision ACM certificate with DNS validation.
 *
 * Creates ACM certificate with DNS validation method. Caller must create DNS
 * records using domain_validation_options output to complete validation.
 */

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"
  key_algorithm             = "RSA_2048"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  # depends_on ensures domain_validation_options is fully populated before
  # iterating; without it the list can be empty if the certificate is still
  # pending, causing silent validation failures.
  depends_on = [aws_acm_certificate.this]

  validation_record_fqdns = [for r in aws_acm_certificate.this.domain_validation_options : r.resource_record_name]
}
