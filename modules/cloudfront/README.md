Provision CloudFront distribution with TLS 1.2+, security headers, and origin failover.

Creates CloudFront distribution with TLSv1.2\_2021 minimum, HTTP/2 and HTTP/3,
security headers via CloudFront function, S3 origins with OAC/SigV4, custom HTTPS
origins, optional WAF, optional ACM certificate with DNS validation, and optional
origin failover.

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.41 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.41.0 |
| <a name="provider_aws.us_east_1"></a> [aws.us\_east\_1](#provider\_aws.us\_east\_1) | 6.41.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.security_headers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_log_bucket"></a> [access\_log\_bucket](#input\_access\_log\_bucket) | S3 bucket domain name for CloudFront access logs (e.g. my-logs-bucket.s3.amazonaws.com). Set to null to disable logging. | `string` | `null` | no |
| <a name="input_access_log_prefix"></a> [access\_log\_prefix](#input\_access\_log\_prefix) | Key prefix for CloudFront access log objects. | `string` | `""` | no |
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | ARN of an existing ACM certificate in us-east-1. Required when aliases is non-empty and create\_certificate is false. | `string` | `null` | no |
| <a name="input_aliases"></a> [aliases](#input\_aliases) | Custom domain aliases for the distribution (e.g. ["example.com"]). | `list(string)` | `[]` | no |
| <a name="input_allowed_methods"></a> [allowed\_methods](#input\_allowed\_methods) | HTTP methods allowed by the default cache behavior. | `list(string)` | <pre>[<br/>  "GET",<br/>  "HEAD"<br/>]</pre> | no |
| <a name="input_cache_policy_id"></a> [cache\_policy\_id](#input\_cache\_policy\_id) | CloudFront cache policy ID. Defaults to AWS managed CachingOptimized. | `string` | `"658327ea-f89d-4fab-a63d-7e88639e58f6"` | no |
| <a name="input_comment"></a> [comment](#input\_comment) | Comment for the CloudFront distribution. | `string` | `null` | no |
| <a name="input_create_certificate"></a> [create\_certificate](#input\_create\_certificate) | Create an ACM certificate for the first alias. Requires aliases to be non-empty. | `bool` | `false` | no |
| <a name="input_custom_error_responses"></a> [custom\_error\_responses](#input\_custom\_error\_responses) | Custom error responses for the distribution. | <pre>list(object({<br/>    error_code            = number<br/>    response_code         = number<br/>    response_page_path    = string<br/>    error_caching_min_ttl = number<br/>  }))</pre> | `[]` | no |
| <a name="input_extra_origins"></a> [extra\_origins](#input\_extra\_origins) | Additional origins beyond the primary origin. | <pre>list(object({<br/>    domain_name               = string<br/>    origin_id                 = string<br/>    origin_access_control_id  = optional(string)<br/>    s3_origin_access_identity = optional(string)<br/>    custom_origin_config = optional(object({<br/>      http_port              = number<br/>      https_port             = number<br/>      origin_protocol_policy = string<br/>      origin_ssl_protocols   = list(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_failover_origin_domain_name"></a> [failover\_origin\_domain\_name](#input\_failover\_origin\_domain\_name) | Domain name of the failover origin. When set, an origin group is created with the primary origin as primary and this as the failover. Enables CKV\_AWS\_310 compliance. | `string` | `null` | no |
| <a name="input_failover_status_codes"></a> [failover\_status\_codes](#input\_failover\_status\_codes) | HTTP status codes that trigger failover to the secondary origin. | `list(number)` | <pre>[<br/>  500,<br/>  502,<br/>  503,<br/>  504<br/>]</pre> | no |
| <a name="input_function_associations"></a> [function\_associations](#input\_function\_associations) | CloudFront function associations for the default cache behavior. | <pre>list(object({<br/>    event_type   = string<br/>    function_arn = string<br/>  }))</pre> | `[]` | no |
| <a name="input_geo_restriction_locations"></a> [geo\_restriction\_locations](#input\_geo\_restriction\_locations) | List of ISO 3166-1 alpha-2 country codes for geo restriction. Required when geo\_restriction\_type is 'whitelist' or 'blacklist'. | `list(string)` | `[]` | no |
| <a name="input_geo_restriction_type"></a> [geo\_restriction\_type](#input\_geo\_restriction\_type) | Type of geo restriction: 'none', 'whitelist', or 'blacklist'. | `string` | `"none"` | no |
| <a name="input_name"></a> [name](#input\_name) | Logical name for the distribution; used to name all child resources. | `string` | n/a | yes |
| <a name="input_ordered_cache_behaviors"></a> [ordered\_cache\_behaviors](#input\_ordered\_cache\_behaviors) | Ordered cache behaviors appended after the default behavior. | <pre>list(object({<br/>    path_pattern             = string<br/>    target_origin_id         = string<br/>    viewer_protocol_policy   = string<br/>    allowed_methods          = list(string)<br/>    cached_methods           = list(string)<br/>    compress                 = bool<br/>    cache_policy_id          = string<br/>    origin_request_policy_id = optional(string)<br/>    trusted_key_groups       = optional(list(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_origin_domain_name"></a> [origin\_domain\_name](#input\_origin\_domain\_name) | Domain name of the origin (S3 regional domain or custom hostname). | `string` | n/a | yes |
| <a name="input_origin_type"></a> [origin\_type](#input\_origin\_type) | Origin type: 's3' (uses OAC + sigv4) or 'custom' (uses HTTPS custom origin). | `string` | `"s3"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_web_acl_id"></a> [web\_acl\_id](#input\_web\_acl\_id) | ARN of a WAFv2 Web ACL to associate with the distribution. If null, no WAF is attached. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_acm_validation_records"></a> [acm\_validation\_records](#output\_acm\_validation\_records) | ACM DNS validation records (only populated when create\_certificate = true). |
| <a name="output_distribution_arn"></a> [distribution\_arn](#output\_distribution\_arn) | CloudFront distribution ARN. |
| <a name="output_distribution_id"></a> [distribution\_id](#output\_distribution\_id) | CloudFront distribution ID. |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | CloudFront distribution domain name. |
| <a name="output_oac_id"></a> [oac\_id](#output\_oac\_id) | Origin Access Control ID (S3 origins only; null for custom origins). |
