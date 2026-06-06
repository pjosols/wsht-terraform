App-account side of centralized secrets access.

Runs in an app account (B, C, D). Produces an IAM policy granting sts:AssumeRole
on the per-app reader role(s) exposed by modules/secrets\_vault in the central
vault account. Attach it to the app's workload role (Lambda/EC2 instance/ECS task
role); the workload then assumes the reader role and calls
secretsmanager:GetSecretValue on its own secrets.

Optionally attaches the policy to existing role(s) via attach\_to\_role\_names; either
way the policy ARN and JSON are exported for the caller to wire up.

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.41 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.49.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_attach_to_role_names"></a> [attach\_to\_role\_names](#input\_attach\_to\_role\_names) | Existing IAM role names to attach the generated policy to. Leave empty to attach it yourself using the policy\_arn output. | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | App/service name. Used to name the IAM policy ("<name>-secrets-access"). | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_vault_role_arns"></a> [vault\_role\_arns](#input\_vault\_role\_arns) | Reader role ARN(s) from the vault account (the reader\_role\_arn output of modules/secrets\_vault) that the workload may assume. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_policy_arn"></a> [policy\_arn](#output\_policy\_arn) | ARN of the IAM policy granting sts:AssumeRole on the vault reader role(s). Attach to your workload role. |
| <a name="output_policy_json"></a> [policy\_json](#output\_policy\_json) | The IAM policy document (JSON) granting sts:AssumeRole on the vault reader role(s). |
| <a name="output_policy_name"></a> [policy\_name](#output\_policy\_name) | Name of the generated IAM policy. |
