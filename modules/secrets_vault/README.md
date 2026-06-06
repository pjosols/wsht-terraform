Per-app secrets footprint in a central "vault" AWS account.

Instantiate once per (app, env). Creates a dedicated cross-account reader IAM
role scoped to that app's secrets only (by path prefix, convention "<app>/<env>",
e.g. appw/prod/*), plus — optionally — the Secrets Manager secret containers.

App accounts (B, C, D) assume *their own* role (not a shared one) to fetch secrets.
The role's permission policy grants secretsmanager:GetSecretValue on
"<path\_prefix>/*", so it can never read another app's secrets. Secrets use the
AWS-managed key (aws/secretsmanager); decryption is same-account (the read happens
under this role, inside the vault account), so no customer-managed KMS key or
cross-account kms:Decrypt grant is required.

This module deliberately manages only secret *containers* and IAM — never secret
*values*. Plaintext therefore never lands in Terraform state. Put values in
out-of-band, e.g. `aws secretsmanager put-secret-value --secret-string file://...`.

Pair with modules/secrets\_consumer in each app account to grant the app's
workload role sts:AssumeRole on the reader\_role\_arn output here.

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
| [aws_iam_role.reader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | If set, assuming the reader role requires this sts:ExternalId (confused-deputy mitigation). The consumer must pass the same value at AssumeRole time. | `string` | `null` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration in seconds for the reader role. 3600–43200. | `number` | `3600` | no |
| <a name="input_name"></a> [name](#input\_name) | Override the derived resource-name base. Defaults to path\_prefix with slashes replaced by dashes (e.g. "appw/prod" -> "appw-prod"). Names the reader role ("<base>-secrets-reader") and its inline policy ("<base>-secrets-read"). Leave null to derive it so the names can't drift from the prefix; set it only when you need a specific role name. | `string` | `null` | no |
| <a name="input_path_prefix"></a> [path\_prefix](#input\_path\_prefix) | Path prefix under which this app's secrets live. House convention is "<app>/<env>", e.g. "appw/prod" — app-first, so an app's secrets group together and an app-wide grant is a single "<app>/*" wildcard. The reader role is scoped to "<path\_prefix>/*", so instantiate once per (app, env) — each (app, env) gets its own role and trusted principals, keeping prod secrets unreadable by a staging role. Drop the env segment (e.g. "appw") for single-account setups. No leading or trailing slash. | `string` | n/a | yes |
| <a name="input_recovery_window_days"></a> [recovery\_window\_days](#input\_recovery\_window\_days) | Days Secrets Manager retains a deleted secret before permanent deletion. 0 forces immediate deletion; otherwise 7–30. | `number` | `30` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | Secret containers to create under path\_prefix. Map key is the short name (full name becomes "<path\_prefix>/<key>"). This module never manages secret *values* — only the empty containers — so plaintext never lands in Terraform state. Set values out-of-band with `aws secretsmanager put-secret-value`. | <pre>map(object({<br/>    description = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_trusted_principals"></a> [trusted\_principals](#input\_trusted\_principals) | ARNs allowed to assume the reader role — typically the app account root ("arn:aws:iam::<app-acct>:root") or specific app workload role ARNs. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_path_prefix"></a> [path\_prefix](#output\_path\_prefix) | The path prefix this app's secrets live under. |
| <a name="output_reader_role_arn"></a> [reader\_role\_arn](#output\_reader\_role\_arn) | ARN of the cross-account reader role. Pass this to modules/secrets\_consumer (vault\_role\_arns) in the app account so its workload role can assume it. |
| <a name="output_reader_role_name"></a> [reader\_role\_name](#output\_reader\_role\_name) | Name of the cross-account reader role. |
| <a name="output_secret_arn_wildcard"></a> [secret\_arn\_wildcard](#output\_secret\_arn\_wildcard) | The "<path\_prefix>/*" ARN pattern the reader role is scoped to. |
| <a name="output_secret_arns"></a> [secret\_arns](#output\_secret\_arns) | Map of short name => ARN for each created secret container (empty if no secrets were created here). |
