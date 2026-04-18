/**
 * Provision CloudFront distribution with TLS 1.2+, security headers, and origin failover.
 *
 * Creates CloudFront distribution with TLSv1.2_2021 minimum, HTTP/2 and HTTP/3,
 * security headers via CloudFront function, S3 origins with OAC/SigV4, custom HTTPS
 * origins, optional WAF, optional ACM certificate with DNS validation, and optional
 * origin failover.
 */

locals {
  # Certificate ARN: prefer explicit input, fall back to created cert.
  effective_cert_arn = var.acm_certificate_arn != null ? var.acm_certificate_arn : (
    var.create_certificate ? aws_acm_certificate_validation.this["enabled"].certificate_arn : null
  )

  use_custom_cert   = length(var.aliases) > 0 && local.effective_cert_arn != null
  use_failover      = var.failover_origin_domain_name != null
  default_origin_id = local.use_failover ? "${var.name}-group" : var.name
}

# ── Security headers function ─────────────────────────────────────────────────

resource "aws_cloudfront_function" "security_headers" {
  name    = "${var.name}-security-headers"
  runtime = "cloudfront-js-2.0"
  publish = true

  code = <<-EOF
    function handler(event) {
      var response = event.response;
      var headers = response.headers;
      headers['x-content-type-options'] = { value: 'nosniff' };
      headers['x-frame-options'] = { value: 'DENY' };
      headers['x-xss-protection'] = { value: '1; mode=block' };
      headers['referrer-policy'] = { value: 'strict-origin-when-cross-origin' };
      headers['strict-transport-security'] = { value: 'max-age=63072000; includeSubDomains; preload' };
      return response;
    }
  EOF
}

# ── Origin Access Control (S3 only) ──────────────────────────────────────────

resource "aws_cloudfront_origin_access_control" "this" {
  for_each = var.origin_type == "s3" ? toset(["enabled"]) : toset([])

  name                              = "${var.name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ── ACM certificate (optional) ────────────────────────────────────────────────

resource "aws_acm_certificate" "this" {
  for_each = var.create_certificate ? toset(["enabled"]) : toset([])
  provider = aws.us_east_1

  domain_name               = var.aliases[0]
  subject_alternative_names = slice(var.aliases, 1, length(var.aliases))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_acm_certificate_validation" "this" {
  for_each = var.create_certificate ? toset(["enabled"]) : toset([])
  provider = aws.us_east_1

  certificate_arn = aws_acm_certificate.this["enabled"].arn

  depends_on = [aws_acm_certificate.this]

  validation_record_fqdns = [for r in aws_acm_certificate.this["enabled"].domain_validation_options : r.resource_record_name]
}

# ── CloudFront distribution ───────────────────────────────────────────────────

resource "aws_cloudfront_distribution" "this" {
  comment             = var.comment
  enabled             = true
  http_version        = "http2and3"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  aliases             = var.aliases
  web_acl_id          = var.web_acl_id

  origin {
    domain_name              = var.origin_domain_name
    origin_id                = var.name
    origin_access_control_id = var.origin_type == "s3" ? aws_cloudfront_origin_access_control.this["enabled"].id : null

    dynamic "custom_origin_config" {
      for_each = var.origin_type == "custom" ? [1] : []
      content {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  dynamic "origin" {
    for_each = var.extra_origins
    content {
      domain_name              = origin.value.domain_name
      origin_id                = origin.value.origin_id
      origin_access_control_id = origin.value.origin_access_control_id

      dynamic "s3_origin_config" {
        for_each = origin.value.s3_origin_access_identity != null ? [1] : []
        content {
          origin_access_identity = origin.value.s3_origin_access_identity
        }
      }

      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config != null ? [origin.value.custom_origin_config] : []
        content {
          http_port              = custom_origin_config.value.http_port
          https_port             = custom_origin_config.value.https_port
          origin_protocol_policy = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols   = custom_origin_config.value.origin_ssl_protocols
        }
      }
    }
  }

  dynamic "origin" {
    for_each = local.use_failover ? [1] : []
    content {
      domain_name = var.failover_origin_domain_name
      origin_id   = "${var.name}-failover"

      dynamic "custom_origin_config" {
        for_each = var.origin_type == "custom" ? [1] : []
        content {
          http_port              = 80
          https_port             = 443
          origin_protocol_policy = "https-only"
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }
    }
  }

  dynamic "origin_group" {
    for_each = local.use_failover ? [1] : []
    content {
      origin_id = "${var.name}-group"
      failover_criteria {
        status_codes = var.failover_status_codes
      }
      member { origin_id = var.name }
      member { origin_id = "${var.name}-failover" }
    }
  }

  default_cache_behavior {
    target_origin_id       = local.default_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = var.allowed_methods
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = var.cache_policy_id

    dynamic "function_association" {
      for_each = var.function_associations
      content {
        event_type   = function_association.value.event_type
        function_arn = function_association.value.function_arn
      }
    }

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern             = ordered_cache_behavior.value.path_pattern
      target_origin_id         = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy   = ordered_cache_behavior.value.viewer_protocol_policy
      allowed_methods          = ordered_cache_behavior.value.allowed_methods
      cached_methods           = ordered_cache_behavior.value.cached_methods
      compress                 = ordered_cache_behavior.value.compress
      cache_policy_id          = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id = ordered_cache_behavior.value.origin_request_policy_id
      trusted_key_groups       = ordered_cache_behavior.value.trusted_key_groups
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  dynamic "logging_config" {
    for_each = var.access_log_bucket != null ? [1] : []
    content {
      bucket          = var.access_log_bucket
      include_cookies = false
      prefix          = var.access_log_prefix
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # minimum_protocol_version must not be set when using cloudfront_default_certificate.
  # When aliases are provided, a custom ACM certificate is required (TLSv1.2_2021 enforced).
  # When no aliases are set, the CloudFront default certificate is used (no custom TLS version).
  viewer_certificate {
    acm_certificate_arn            = local.use_custom_cert ? local.effective_cert_arn : null
    ssl_support_method             = local.use_custom_cert ? "sni-only" : null
    minimum_protocol_version       = local.use_custom_cert ? "TLSv1.2_2021" : null # nosemgrep: terraform.aws.security.aws-cloudfront-insecure-tls.aws-insecure-cloudfront-distribution-tls-version -- cloudfront_default_certificate path does not accept minimum_protocol_version; TLSv1.2_2021 is enforced on all custom-cert distributions
    cloudfront_default_certificate = local.use_custom_cert ? null : true
  }

  tags = var.tags
}
