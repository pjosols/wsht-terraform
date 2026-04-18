# ADR-005: CloudFront — Certificate Selection Priority and Failover Origin Group

## Status
Accepted

## Context
The `cloudfront` module must handle three distinct TLS/certificate scenarios:

1. No custom domain — use the CloudFront default certificate (`*.cloudfront.net`).
2. Custom domain, certificate managed elsewhere — caller supplies an existing ACM certificate ARN.
3. Custom domain, certificate managed by the module — module creates and DNS-validates an ACM certificate.

CloudFront rejects a distribution that has `aliases` set but no certificate. It also rejects `minimum_protocol_version` when `cloudfront_default_certificate = true` is set. These constraints mean the certificate path must be resolved before the distribution resource is rendered.

The module also optionally supports an origin failover group. When a failover origin is configured, the `target_origin_id` on the default cache behavior must point to the origin group, not the primary origin directly. This ID must be consistent across the `origin_group`, `cache_behavior`, and the two `origin` blocks.

## Decision
Three locals resolve all TLS and origin behavior before any resource is declared:

```hcl
locals {
  effective_cert_arn = var.acm_certificate_arn != null ? var.acm_certificate_arn : (
    var.create_certificate ? aws_acm_certificate_validation.this["enabled"].certificate_arn : null
  )
  use_custom_cert   = length(var.aliases) > 0 && local.effective_cert_arn != null
  use_failover      = var.failover_origin_domain_name != null
  default_origin_id = local.use_failover ? "${var.name}-group" : var.name
}
```

`effective_cert_arn` resolves in priority order: explicit input (`acm_certificate_arn`) wins over module-created (`create_certificate`). If a caller passes both, the pre-existing cert is used and the module-created cert is still provisioned but never attached.

`use_custom_cert` gates the `viewer_certificate` block: when true, `acm_certificate_arn` and `minimum_protocol_version = "TLSv1.2_2021"` are set; when false, `cloudfront_default_certificate = true` is set and `minimum_protocol_version` is omitted.

When `failover_origin_domain_name` is set, the module creates a second origin block and an `aws_cloudfront_origin_group` wrapping both. `default_origin_id` is set to `"${var.name}-group"` so the cache behavior targets the group. CloudFront routes to the primary first; on a response matching `failover_status_codes` (default: 500, 502, 503, 504) it retries against the failover origin. The failover origin uses the same `origin_type` as the primary.

## Alternatives Considered

**Require callers to always supply a certificate ARN** — This removes the `create_certificate` convenience path. Callers managing a simple single-distribution setup would need a separate ACM module and a cross-module reference. The three-path model covers the common cases without requiring extra modules.

**Module-created cert wins when both are supplied** — Reversing the priority would silently ignore a caller-supplied cert when `create_certificate = true` is also set. Explicit input winning is the less surprising behavior: a caller who passes `acm_certificate_arn` intends to use that cert.

**Separate `failover` module** — Splitting failover into a separate module adds caller complexity and splits related CloudFront configuration across two modules. The origin group is tightly coupled to the distribution's cache behavior; keeping them together avoids the need to pass the group ID across module boundaries.

**Hardcode `TLSv1.2_2021` for all distributions** — CloudFront rejects `minimum_protocol_version` alongside `cloudfront_default_certificate = true`. The field must be conditionally omitted for distributions without a custom cert. A hardcoded value would require suppressing the CloudFront API error rather than avoiding it.

## Consequences
- `use_custom_cert` is only true when both `aliases` is non-empty and a cert ARN is resolved. A distribution with aliases but no cert is never created — CloudFront would reject it at apply time anyway, but the local prevents the plan from reaching that state.
- When `create_certificate = true`, the distribution is not created until ACM DNS validation completes. This can take several minutes on first apply.
- The failover origin must use the same `origin_type` as the primary. Mixed-type failover (e.g. S3 primary, custom failover) is not supported by this module.
- If a caller passes both `acm_certificate_arn` and `create_certificate = true`, the module-created cert is provisioned but unused. This wastes a cert but does not break anything. Callers should not set both.
