# cloudfront-s3

Wires together `s3_bucket`, `cloudfront`, `waf`, and `acm` into a static-site or asset-delivery stack.

## What this creates

| Module | Purpose |
|---|---|
| `waf` | WAFv2 Web ACL with rate limiting and AWS managed rules |
| `acm` | ACM certificate with DNS validation for the custom domain |
| `s3_bucket` | Private S3 origin bucket (public access blocked) |
| `cloudfront` | Distribution with OAC/SigV4 S3 access, TLS 1.2+, WAF, and security headers |

## Usage

```hcl
module "my_site" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//examples/cloudfront-s3?ref=v1.0.0"

  name   = "my-site"
  domain = "example.com"

  tags = {
    env     = "prod"
    project = "wsht"
  }
}
```

## Key wiring

- `waf.web_acl_arn` → `cloudfront.web_acl_id` — WAF protects the distribution
- `acm.certificate_arn` → `cloudfront.acm_certificate_arn` — TLS for the custom domain
- `s3.bucket_regional_domain_name` → `cloudfront.origin_domain_name` — CloudFront fetches from S3 via OAC

## Notes

- No backend is configured — callers supply their own `terraform { backend ... }` block.
- After `terraform apply`, create the DNS records from `acm_validation_records` output to complete certificate validation before CloudFront can serve HTTPS traffic.
- The S3 bucket policy granting CloudFront OAC access is managed by the `cloudfront` module; no manual bucket policy is needed.
- WAF is scoped to `CLOUDFRONT` and must be created in `us-east-1` (enforced by the `waf` module).
