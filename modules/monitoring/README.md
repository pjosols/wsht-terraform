Provision CloudWatch alarms for Lambda errors, duration, and throttles.

Creates CloudWatch metric alarms for Lambda function errors, duration (with
configurable threshold percentage), and throttles. Optionally creates EventBridge
scheduled rule for canary/health-check invocation.

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
| [aws_cloudwatch_event_rule.schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_metric_alarm.duration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.throttles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_duration_threshold_pct"></a> [duration\_threshold\_pct](#input\_duration\_threshold\_pct) | Percentage of lambda\_timeout at which the duration alarm fires (0–100). | `number` | `80` | no |
| <a name="input_error_threshold"></a> [error\_threshold](#input\_error\_threshold) | Number of Lambda errors per period that triggers the error alarm. | `number` | `1` | no |
| <a name="input_lambda_function_arn"></a> [lambda\_function\_arn](#input\_lambda\_function\_arn) | ARN of the Lambda function. Used as the EventBridge schedule target. Required when schedule\_expression is set. | `string` | `""` | no |
| <a name="input_lambda_function_name"></a> [lambda\_function\_name](#input\_lambda\_function\_name) | Name of the Lambda function to monitor. | `string` | n/a | yes |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | Lambda timeout in seconds. Used to compute the duration alarm threshold. | `number` | n/a | yes |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | Optional EventBridge schedule expression (e.g. 'rate(5 minutes)') to periodically invoke the Lambda for scheduled monitoring. Leave empty to skip. | `string` | `""` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | ARN of the SNS topic to send alarm notifications to. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_duration_alarm_arn"></a> [duration\_alarm\_arn](#output\_duration\_alarm\_arn) | ARN of the Lambda duration alarm. |
| <a name="output_error_alarm_arn"></a> [error\_alarm\_arn](#output\_error\_alarm\_arn) | ARN of the Lambda error count alarm. |
| <a name="output_schedule_rule_arn"></a> [schedule\_rule\_arn](#output\_schedule\_rule\_arn) | ARN of the EventBridge schedule rule, if schedule\_expression was set. |
| <a name="output_throttles_alarm_arn"></a> [throttles\_alarm\_arn](#output\_throttles\_alarm\_arn) | ARN of the Lambda throttles alarm. |
