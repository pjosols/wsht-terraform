Provision KMS key with alias, rotation, and deletion protection.

Creates customer-managed KMS key with automatic key rotation enabled,
deletion protection, and alias. Grants root account full key management
permissions and caller-supplied principals read/decrypt access.

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
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_policy_statements"></a> [additional\_policy\_statements](#input\_additional\_policy\_statements) | Optional list of additional IAM policy statement objects to merge into the key policy. | <pre>list(object({<br/>    sid           = optional(string)<br/>    effect        = optional(string, "Allow")<br/>    actions       = list(string)<br/>    not_actions   = optional(list(string))<br/>    resources     = optional(list(string), ["*"])<br/>    not_resources = optional(list(string))<br/>    principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })))<br/>    conditions = optional(list(object({<br/>      test     = string<br/>      variable = string<br/>      values   = list(string)<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_alias_prefix"></a> [alias\_prefix](#input\_alias\_prefix) | Optional prefix for the KMS alias. When set, the alias becomes alias/<prefix>-<name>. When empty, the alias is alias/<name>. | `string` | `""` | no |
| <a name="input_description"></a> [description](#input\_description) | Human-readable description for the KMS key. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Key name, used to form the KMS alias. | `string` | n/a | yes |
| <a name="input_service_principals"></a> [service\_principals](#input\_service\_principals) | List of AWS service principals (e.g. 'logs.us-east-1.amazonaws.com') granted Encrypt/Decrypt/GenerateDataKey permissions. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_alias_arn"></a> [alias\_arn](#output\_alias\_arn) | ARN of the KMS alias. |
| <a name="output_key_arn"></a> [key\_arn](#output\_key\_arn) | ARN of the KMS key. |
| <a name="output_key_id"></a> [key\_id](#output\_key\_id) | ID of the KMS key. |
