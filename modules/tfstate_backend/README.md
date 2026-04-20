Provision S3 bucket and DynamoDB table for Terraform remote state backend.

The S3 bucket is created via the s3\_bucket module (versioning, encryption,
SSL-only policy, and public access block included). The DynamoDB table uses
PAY\_PER\_REQUEST billing with point-in-time recovery and optional KMS encryption.

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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_bucket"></a> [bucket](#module\_bucket) | ../s3_bucket | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_dynamodb_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Override the default bucket name. Defaults to '<project>-tfstate'. | `string` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS key ARN for S3 and DynamoDB encryption. If null, AES256/AWS-managed keys are used. | `string` | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name. Used to derive bucket name (<project>-tfstate) and table name (<project>-tfstate-lock). | `string` | n/a | yes |
| <a name="input_table_name"></a> [table\_name](#input\_table\_name) | Override the default DynamoDB table name. Defaults to '<project>-tfstate-lock'. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backend_config"></a> [backend\_config](#output\_backend\_config) | Ready-to-paste backend block values. |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the S3 state bucket. |
| <a name="output_table_name"></a> [table\_name](#output\_table\_name) | Name of the DynamoDB lock table. |
