mock_provider "aws" {
  mock_resource "aws_cloudfront_function" {
    defaults = {
      arn = "arn:aws:cloudfront::123456789012:function/test-cf-security-headers"
    }
  }
}
mock_provider "aws" {
  alias = "us_east_1"
}

# ── Minimal S3 origin apply succeeds, key outputs populated ──────────────────

run "s3_origin_outputs_populated" {
  command = apply

  variables {
    name               = "test-cf"
    origin_domain_name = "my-bucket.s3.us-east-1.amazonaws.com"
  }

  assert {
    condition     = output.distribution_id != null
    error_message = "distribution_id must not be null"
  }

  assert {
    condition     = output.domain_name != null
    error_message = "domain_name must not be null"
  }

  assert {
    condition     = output.oac_id != null
    error_message = "oac_id must not be null for s3 origin"
  }
}

# ── Custom origin: oac_id is null ─────────────────────────────────────────────

run "custom_origin_oac_id_null" {
  command = apply

  variables {
    name               = "test-cf-custom"
    origin_domain_name = "api.example.com"
    origin_type        = "custom"
  }

  assert {
    condition     = output.oac_id == null
    error_message = "oac_id must be null for custom origin"
  }
}

# ── Invalid origin_type rejected ──────────────────────────────────────────────

run "invalid_origin_type_rejected" {
  command = plan

  variables {
    name               = "test-cf"
    origin_domain_name = "my-bucket.s3.us-east-1.amazonaws.com"
    origin_type        = "ftp"
  }

  expect_failures = [var.origin_type]
}

# ── Invalid geo_restriction_type rejected ─────────────────────────────────────

run "invalid_geo_restriction_type_rejected" {
  command = plan

  variables {
    name                 = "test-cf"
    origin_domain_name   = "my-bucket.s3.us-east-1.amazonaws.com"
    geo_restriction_type = "invalid"
  }

  expect_failures = [var.geo_restriction_type]
}

# ── Security headers function always attached (regression) ────────────────────
# Ensures the built-in viewer-response security-headers function is never removed.

run "security_headers_function_always_present" {
  command = plan

  variables {
    name               = "test-cf"
    origin_domain_name = "my-bucket.s3.us-east-1.amazonaws.com"
  }

  assert {
    condition = anytrue([
      for fa in aws_cloudfront_distribution.this.default_cache_behavior[0].function_association :
      fa.event_type == "viewer-response"
    ])
    error_message = "security headers viewer-response function association must always be present"
  }
}

# ── TLS 1.2 enforced when aliases provided (regression) ──────────────────────

run "tls12_enforced_with_aliases" {
  command = plan

  variables {
    name                = "test-cf"
    origin_domain_name  = "my-bucket.s3.us-east-1.amazonaws.com"
    aliases             = ["example.com"]
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].minimum_protocol_version == "TLSv1.2_2021"
    error_message = "minimum_protocol_version must be TLSv1.2_2021 when aliases are set"
  }
}

# ── TLS: default cert path uses cloudfront_default_certificate, no custom TLS ─
# Regression: ensures the no-alias path doesn't accidentally set
# minimum_protocol_version (which is invalid with cloudfront_default_certificate).

run "default_cert_no_minimum_protocol_version" {
  command = plan

  variables {
    name               = "test-cf"
    origin_domain_name = "my-bucket.s3.us-east-1.amazonaws.com"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].cloudfront_default_certificate == true
    error_message = "cloudfront_default_certificate must be true when no aliases are set"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].minimum_protocol_version == null
    error_message = "minimum_protocol_version must be null when using cloudfront_default_certificate"
  }
}

# ── TLS: custom cert path sets sni-only and TLSv1.2_2021 ─────────────────────
# Regression: ensures both ssl_support_method and minimum_protocol_version are
# set together whenever a custom certificate is used.

run "custom_cert_sni_and_tls_version_set" {
  command = plan

  variables {
    name                = "test-cf"
    origin_domain_name  = "my-bucket.s3.us-east-1.amazonaws.com"
    aliases             = ["example.com"]
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].ssl_support_method == "sni-only"
    error_message = "ssl_support_method must be sni-only when aliases are set"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].cloudfront_default_certificate == null
    error_message = "cloudfront_default_certificate must be null when a custom cert is used"
  }
}

# ── acm_validation_records empty when create_certificate = false ──────────────

run "acm_validation_records_empty_by_default" {
  command = apply

  variables {
    name               = "test-cf"
    origin_domain_name = "my-bucket.s3.us-east-1.amazonaws.com"
  }

  assert {
    condition     = length(output.acm_validation_records) == 0
    error_message = "acm_validation_records must be empty when create_certificate is false"
  }
}

# ── for_each: OAC resource set has key "enabled" for s3 origin (regression) ──
# Ensures the for_each migration didn't break OAC creation — resource must be
# addressable by key "enabled", not numeric index.

run "oac_for_each_key_enabled_s3" {
  command = plan

  variables {
    name               = "test-cf"
    origin_domain_name = "my-bucket.s3.us-east-1.amazonaws.com"
    origin_type        = "s3"
  }

  assert {
    condition     = length(aws_cloudfront_origin_access_control.this) == 1
    error_message = "OAC for_each set must have exactly one entry for s3 origin"
  }

  assert {
    condition     = contains(keys(aws_cloudfront_origin_access_control.this), "enabled")
    error_message = "OAC for_each key must be 'enabled', not a numeric index"
  }
}

# ── for_each: OAC resource set is empty for custom origin (regression) ────────

run "oac_for_each_empty_custom" {
  command = plan

  variables {
    name               = "test-cf"
    origin_domain_name = "api.example.com"
    origin_type        = "custom"
  }

  assert {
    condition     = length(aws_cloudfront_origin_access_control.this) == 0
    error_message = "OAC for_each set must be empty for custom origin"
  }
}

# ── for_each: ACM cert resource set has key "enabled" when create_certificate ─

run "acm_cert_for_each_key_enabled" {
  command = plan

  variables {
    name               = "test-cf"
    origin_domain_name = "my-bucket.s3.us-east-1.amazonaws.com"
    aliases            = ["example.com"]
    create_certificate = true
  }

  assert {
    condition     = length(aws_acm_certificate.this) == 1
    error_message = "ACM cert for_each set must have exactly one entry when create_certificate = true"
  }

  assert {
    condition     = contains(keys(aws_acm_certificate.this), "enabled")
    error_message = "ACM cert for_each key must be 'enabled', not a numeric index"
  }
}

# ── for_each: ACM cert resource set is empty when create_certificate = false ──

run "acm_cert_for_each_empty_by_default" {
  command = plan

  variables {
    name               = "test-cf"
    origin_domain_name = "my-bucket.s3.us-east-1.amazonaws.com"
  }

  assert {
    condition     = length(aws_acm_certificate.this) == 0
    error_message = "ACM cert for_each set must be empty when create_certificate = false"
  }
}

# ── Certificate selection: explicit acm_certificate_arn takes priority ────────
# Regression: when both acm_certificate_arn and create_certificate are set,
# the explicit ARN must win (effective_cert_arn = var.acm_certificate_arn).

run "explicit_cert_arn_takes_priority_over_created_cert" {
  command = plan

  variables {
    name                = "test-cf"
    origin_domain_name  = "my-bucket.s3.us-east-1.amazonaws.com"
    aliases             = ["example.com"]
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/explicit"
    create_certificate  = true
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].acm_certificate_arn == "arn:aws:acm:us-east-1:123456789012:certificate/explicit"
    error_message = "explicit acm_certificate_arn must take priority over create_certificate"
  }
}

# ── Failover: origin group created when failover_origin_domain_name is set ────

run "failover_origin_group_created" {
  command = plan

  variables {
    name                        = "test-cf"
    origin_domain_name          = "primary.example.com"
    origin_type                 = "custom"
    failover_origin_domain_name = "failover.example.com"
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this.origin_group) == 1
    error_message = "origin_group must be created when failover_origin_domain_name is set"
  }
}

# ── Failover: no origin group when failover_origin_domain_name is null ────────

run "no_failover_origin_group_by_default" {
  command = plan

  variables {
    name               = "test-cf"
    origin_domain_name = "my-bucket.s3.us-east-1.amazonaws.com"
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this.origin_group) == 0
    error_message = "origin_group must not be created when failover_origin_domain_name is null"
  }
}

# ── Failover: default cache behavior targets the origin group ─────────────────
# When failover is enabled, default_origin_id must be "<name>-group" so traffic
# routes through the origin group rather than directly to the primary origin.

run "failover_default_origin_id_is_group" {
  command = plan

  variables {
    name                        = "test-cf"
    origin_domain_name          = "primary.example.com"
    origin_type                 = "custom"
    failover_origin_domain_name = "failover.example.com"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].target_origin_id == "test-cf-group"
    error_message = "target_origin_id must be '<name>-group' when failover is enabled"
  }
}

# ── No failover: default cache behavior targets the primary origin directly ───

run "no_failover_default_origin_id_is_primary" {
  command = plan

  variables {
    name               = "test-cf"
    origin_domain_name = "my-bucket.s3.us-east-1.amazonaws.com"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].target_origin_id == "test-cf"
    error_message = "target_origin_id must be '<name>' when failover is disabled"
  }
}

# ── Failover: custom status codes are applied to the origin group ─────────────

run "failover_custom_status_codes" {
  command = plan

  variables {
    name                        = "test-cf"
    origin_domain_name          = "primary.example.com"
    origin_type                 = "custom"
    failover_origin_domain_name = "failover.example.com"
    failover_status_codes       = [503, 504]
  }

  assert {
    condition = anytrue([
      for og in aws_cloudfront_distribution.this.origin_group :
      toset(og.failover_criteria[0].status_codes) == toset([503, 504])
    ])
    error_message = "failover_status_codes must be applied to the origin group failover criteria"
  }
}
