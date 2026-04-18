Opinionated HTTP API Gateway (v2) module with Lambda proxy integration.

Creates API Gateway HTTP API, $default stage with access logging, Lambda
proxy integration, configurable routes, CloudWatch log group, and Lambda
invoke permission. Supports multiple named JWT/REQUEST authorizers and CORS.

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
| [aws_apigatewayv2_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_authorizer.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_authorizer) | resource |
| [aws_apigatewayv2_integration.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_cloudwatch_log_group.access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_lambda_permission.apigw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_authorizer_configs"></a> [authorizer\_configs](#input\_authorizer\_configs) | Map of named authorizer configurations. Routes reference authorizers by key. type must be JWT or REQUEST. | <pre>map(object({<br/>    type             = string<br/>    name             = string<br/>    identity_sources = list(string)<br/>    jwt = optional(object({<br/>      audience = list(string)<br/>      issuer   = string<br/>    }))<br/>    authorizer_uri          = optional(string)<br/>    payload_format_version  = optional(string, "2.0")<br/>    enable_simple_responses = optional(bool, true)<br/>    result_ttl_seconds      = optional(number, 0)<br/>  }))</pre> | `{}` | no |
| <a name="input_cors_config"></a> [cors\_config](#input\_cors\_config) | Optional CORS configuration. Disabled by default. | <pre>object({<br/>    allow_origins     = list(string)<br/>    allow_methods     = list(string)<br/>    allow_headers     = list(string)<br/>    expose_headers    = optional(list(string), [])<br/>    max_age           = optional(number, 300)<br/>    allow_credentials = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | API description. | `string` | `""` | no |
| <a name="input_extra_lambda_permissions"></a> [extra\_lambda\_permissions](#input\_extra\_lambda\_permissions) | Map of extra Lambda invoke permissions to create (e.g. for REQUEST authorizer Lambdas). Key is statement\_id suffix, value is function\_name. | `map(string)` | `{}` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS key ARN for encrypting the access log group. | `string` | `null` | no |
| <a name="input_lambda_function_name"></a> [lambda\_function\_name](#input\_lambda\_function\_name) | Lambda function name for the invoke permission. | `string` | n/a | yes |
| <a name="input_lambda_invoke_arn"></a> [lambda\_invoke\_arn](#input\_lambda\_invoke\_arn) | Invoke ARN of the Lambda function to integrate with. | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log group retention in days. | `number` | `365` | no |
| <a name="input_name"></a> [name](#input\_name) | API name. Used in resource names and log group path. | `string` | n/a | yes |
| <a name="input_routes"></a> [routes](#input\_routes) | List of routes to create. Each route has method, path, authorizer (NONE or a key from authorizer\_configs), and optional per-route throttle overrides. | <pre>list(object({<br/>    method                 = string<br/>    path                   = string<br/>    authorizer             = optional(string, "NONE")<br/>    throttling_rate_limit  = optional(number)<br/>    throttling_burst_limit = optional(number)<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources. | `map(string)` | `{}` | no |
| <a name="input_throttling_burst_limit"></a> [throttling\_burst\_limit](#input\_throttling\_burst\_limit) | Default route throttling burst limit. | `number` | `100` | no |
| <a name="input_throttling_rate_limit"></a> [throttling\_rate\_limit](#input\_throttling\_rate\_limit) | Default route throttling rate limit (requests per second). | `number` | `50` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_api_endpoint"></a> [api\_endpoint](#output\_api\_endpoint) | Default endpoint URL of the API Gateway HTTP API. |
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | ID of the API Gateway HTTP API. |
| <a name="output_execution_arn"></a> [execution\_arn](#output\_execution\_arn) | Execution ARN of the API Gateway HTTP API (for Lambda permissions). |
| <a name="output_stage_id"></a> [stage\_id](#output\_stage\_id) | ID of the $default stage. |
