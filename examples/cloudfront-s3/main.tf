module "waf" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/waf?ref=v1.0.0"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name       = var.name
  rate_limit = 1000

  tags = var.tags
}

module "acm" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/acm?ref=v1.0.0"

  domain_name = var.domain

  tags = var.tags
}

module "s3" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/s3_bucket?ref=v1.0.0"

  name = "${var.name}-origin"

  tags = var.tags
}

module "cloudfront" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/cloudfront?ref=v1.0.0"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name               = var.name
  origin_domain_name = module.s3.bucket_regional_domain_name
  origin_type        = "s3"

  aliases             = [var.domain]
  acm_certificate_arn = module.acm.certificate_arn

  web_acl_id = module.waf.web_acl_arn

  tags = var.tags
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name."
  value       = module.cloudfront.domain_name
}

output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = module.cloudfront.distribution_id
}

output "acm_validation_records" {
  description = "DNS records to create to validate the ACM certificate."
  value       = module.acm.domain_validation_options
}
