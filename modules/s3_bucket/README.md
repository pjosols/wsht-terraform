Provision S3 bucket with public access block, encryption, versioning, SSL-only policy, and lifecycle rules.

Creates S3 bucket with public access blocked, server-side encryption (KMS or AES256),
versioning enabled, SSL-only bucket policy, multipart upload cleanup, optional logging,
CORS, accelerate, and event notifications.

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.41 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.41.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_accelerate_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_accelerate_configuration) | resource |
| [aws_s3_bucket_cors_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_notification.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_accelerate"></a> [accelerate](#input\_accelerate) | Enable S3 Transfer Acceleration. | `bool` | `false` | no |
| <a name="input_cors_rules"></a> [cors\_rules](#input\_cors\_rules) | List of CORS rules. If null, no CORS configuration is created. allowed\_headers defaults to ["*"] (all headers allowed); set explicitly to restrict. max\_age\_seconds defaults to 3600; set to 0 to disable preflight caching. | <pre>list(object({<br/>    allowed_methods = list(string)<br/>    allowed_origins = list(string)<br/>    allowed_headers = optional(list(string), ["*"])<br/>    max_age_seconds = optional(number, 3600)<br/>  }))</pre> | `null` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow Terraform to destroy the bucket even if it contains objects. | `bool` | `false` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS key ARN for server-side encryption. If null, AES256 is used. | `string` | `null` | no |
| <a name="input_logging_bucket_id"></a> [logging\_bucket\_id](#input\_logging\_bucket\_id) | ID of the S3 bucket to receive access logs. If null, logging is not enabled. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | S3 bucket name. | `string` | n/a | yes |
| <a name="input_notification_config"></a> [notification\_config](#input\_notification\_config) | S3 bucket notification configuration for Lambda triggers. If null, no notification is created. | <pre>object({<br/>    lambda_functions = list(object({<br/>      lambda_function_arn = string<br/>      events              = list(string)<br/>      filter_prefix       = optional(string, "")<br/>      filter_suffix       = optional(string, "")<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_object_ownership"></a> [object\_ownership](#input\_object\_ownership) | S3 object ownership setting. If null, no ownership controls resource is created. | `string` | `null` | no |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | Bucket policy JSON string. If null, no bucket policy is created. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 bucket. |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | Global domain name of the S3 bucket (for CloudFront logging config). |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name (ID) of the S3 bucket. |
| <a name="output_bucket_policy_document"></a> [bucket\_policy\_document](#output\_bucket\_policy\_document) | The merged bucket policy JSON applied to the bucket (SSL-deny plus any caller-supplied statements). |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | Regional domain name of the S3 bucket (for CloudFront origins). |
