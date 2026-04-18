Provision Cognito user pool with password policy, MFA, and email verification.

Creates user pool with admin-only user creation, email as username attribute,
strong password policy (12+ chars, mixed case, numbers, symbols), optional MFA,
and email verification.

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
| [aws_cognito_user_pool.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_token_validity"></a> [access\_token\_validity](#input\_access\_token\_validity) | Access token validity in hours. | `number` | `1` | no |
| <a name="input_callback_urls"></a> [callback\_urls](#input\_callback\_urls) | Allowed OAuth callback URLs for the app client. | `list(string)` | `[]` | no |
| <a name="input_explicit_auth_flows"></a> [explicit\_auth\_flows](#input\_explicit\_auth\_flows) | List of explicit auth flows to enable on the app client. | `list(string)` | n/a | yes |
| <a name="input_id_token_validity"></a> [id\_token\_validity](#input\_id\_token\_validity) | ID token validity in hours. | `number` | `1` | no |
| <a name="input_logout_urls"></a> [logout\_urls](#input\_logout\_urls) | Allowed OAuth logout URLs for the app client. | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | User pool name. | `string` | n/a | yes |
| <a name="input_refresh_token_validity"></a> [refresh\_token\_validity](#input\_refresh\_token\_validity) | Refresh token validity in days. | `number` | `30` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_client_id"></a> [client\_id](#output\_client\_id) | Cognito User Pool Client ID. |
| <a name="output_user_pool_arn"></a> [user\_pool\_arn](#output\_user\_pool\_arn) | Cognito User Pool ARN. |
| <a name="output_user_pool_id"></a> [user\_pool\_id](#output\_user\_pool\_id) | Cognito User Pool ID. |
