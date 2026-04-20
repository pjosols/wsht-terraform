Provision an AWS Organizations member account with SSO assignments.

Creates a member account under the organization and assigns one or more
SSO principals (users or groups) to the account with specified permission sets.

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
| [aws_organizations_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |
| [aws_ssoadmin_account_assignment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_account_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | Display name for the AWS Organizations account. | `string` | n/a | yes |
| <a name="input_assignments"></a> [assignments](#input\_assignments) | List of {principal\_id, principal\_type, permission\_set\_arn} to assign to this account. | <pre>list(object({<br/>    principal_id       = string<br/>    principal_type     = string<br/>    permission_set_arn = string<br/>  }))</pre> | `[]` | no |
| <a name="input_email"></a> [email](#input\_email) | Unique email address for the account root user. | `string` | n/a | yes |
| <a name="input_iam_user_access_to_billing"></a> [iam\_user\_access\_to\_billing](#input\_iam\_user\_access\_to\_billing) | Allow IAM users to access billing. ALLOW or DENY. | `string` | `"DENY"` | no |
| <a name="input_parent_id"></a> [parent\_id](#input\_parent\_id) | Organizations OU or root ID to place the account in. Defaults to org root. | `string` | `null` | no |
| <a name="input_sso_instance_arn"></a> [sso\_instance\_arn](#input\_sso\_instance\_arn) | ARN of the IAM Identity Center instance. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the Organizations account resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_arn"></a> [account\_arn](#output\_account\_arn) | The ARN of the created account. |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The AWS account ID of the created account. |
