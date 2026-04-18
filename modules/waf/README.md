Provision WAF Web ACL with rate limiting and AWS managed rule groups.

Creates WAF Web ACL with rate limiting at priority 0, AWS Managed Rules
(Common Rule Set + Known Bad Inputs) at priority 1-2, and optional additional
managed rules starting at priority 10. Must be deployed in us-east-1.

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.41 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws.us_east_1"></a> [aws.us\_east\_1](#provider\_aws.us\_east\_1) | 6.41.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_wafv2_web_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_managed_rules"></a> [additional\_managed\_rules](#input\_additional\_managed\_rules) | Optional list of extra managed rule group objects to add. Each object: { name, vendor\_name, priority, metric\_suffix, version (optional) }. | <pre>list(object({<br/>    name          = string<br/>    vendor_name   = string<br/>    priority      = number<br/>    metric_suffix = string<br/>    version       = optional(string, "")<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the Web ACL and associated resources. | `string` | n/a | yes |
| <a name="input_rate_limit"></a> [rate\_limit](#input\_rate\_limit) | Maximum requests per 5-minute window before rate limiting kicks in. | `number` | `1000` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_web_acl_arn"></a> [web\_acl\_arn](#output\_web\_acl\_arn) | ARN of the WAF Web ACL. |
| <a name="output_web_acl_id"></a> [web\_acl\_id](#output\_web\_acl\_id) | ID of the WAF Web ACL. |
