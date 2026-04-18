Provision Lambda function with ECR image, CloudWatch logs, and IAM role.

Creates ECR repository with image scanning and lifecycle policy, CloudWatch
log group with KMS encryption, IAM role with base permissions (logs, ECR),
and Lambda function with arm64 architecture, X-Ray tracing, and optional
VPC configuration. Caller supplies image\_uri and iam\_policy\_json.

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
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.caller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.logs_and_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_dead_letter_arn"></a> [dead\_letter\_arn](#input\_dead\_letter\_arn) | ARN of SQS queue or SNS topic for Lambda dead-letter config. Prevents silent loss of failed async invocations. | `string` | `null` | no |
| <a name="input_ecr_keep_image_count"></a> [ecr\_keep\_image\_count](#input\_ecr\_keep\_image\_count) | Number of ECR images to retain via lifecycle policy. | `number` | `5` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables to set on the Lambda function. | `map(string)` | `{}` | no |
| <a name="input_ephemeral_storage_mb"></a> [ephemeral\_storage\_mb](#input\_ephemeral\_storage\_mb) | Ephemeral /tmp storage in MB (512–10240). Increase for video/image processing workloads. | `number` | `512` | no |
| <a name="input_iam_policy_json"></a> [iam\_policy\_json](#input\_iam\_policy\_json) | IAM policy JSON string granting the Lambda permissions beyond logs and ECR pull. | `string` | n/a | yes |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | ECR image URI to deploy (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/repo:tag). | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS key ARN for encrypting Lambda environment variables, CloudWatch log group, and ECR repository. | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log group retention in days. | `number` | `30` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Lambda memory in MB. | `number` | `256` | no |
| <a name="input_name"></a> [name](#input\_name) | Lambda function name (e.g. 'page-generator'). Used in all resource names. | `string` | n/a | yes |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | IAM permissions boundary ARN to attach to the Lambda execution role. Enables org-level guardrails. | `string` | `null` | no |
| <a name="input_reserved_concurrent_executions"></a> [reserved\_concurrent\_executions](#input\_reserved\_concurrent\_executions) | Reserved concurrency limit for the Lambda. Null means unreserved (uses account pool). | `number` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Lambda timeout in seconds. | `number` | `30` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | Optional VPC configuration for the Lambda. | <pre>object({<br/>    subnet_ids         = list(string)<br/>    security_group_ids = list(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | ARN of the ECR repository. |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | URL of the ECR repository. |
| <a name="output_function_arn"></a> [function\_arn](#output\_function\_arn) | ARN of the Lambda function. |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | Name of the Lambda function. |
| <a name="output_invoke_arn"></a> [invoke\_arn](#output\_invoke\_arn) | Invoke ARN of the Lambda function (for API Gateway integrations). |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | Name of the CloudWatch log group. |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the Lambda IAM role. |
| <a name="output_role_id"></a> [role\_id](#output\_role\_id) | ID (name) of the Lambda IAM role, for attaching additional inline policies. |
