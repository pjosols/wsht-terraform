# lambda-with-apigw

Wires together `lambda_container`, `apigw`, `kms`, and `monitoring` into a complete serverless API.

## What this creates

| Module | Purpose |
|---|---|
| `kms` | Shared key encrypting Lambda env vars, CloudWatch logs, and API Gateway access logs |
| `lambda_container` | Container Lambda with ECR repo, IAM role, and log group |
| `apigw` | HTTP API (API Gateway v2) routing to the Lambda |
| `monitoring` | CloudWatch alarms for errors, duration, and throttles |

## Usage

```hcl
module "my_service" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//examples/lambda-with-apigw?ref=v1.0.0"

  name      = "my-service"
  image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-service:latest"

  tags = {
    env     = "prod"
    project = "wsht"
  }
}
```

## Key wiring

- `kms.key_arn` → `lambda.kms_key_arn` and `apigw.kms_key_arn` — single key encrypts all log groups
- `lambda.invoke_arn` + `lambda.function_name` → `apigw` — grants API Gateway permission to invoke the function
- `lambda.function_arn` + `lambda.function_name` → `monitoring` — alarms target the correct function

## Notes

- No backend is configured — callers supply their own `terraform { backend ... }` block.
- The `sns_topic_arn` local is a placeholder; replace it with a real SNS topic ARN for alarm delivery.
- The `iam_policy_json` in `main.tf` grants the Lambda permission to use the KMS key. Extend it with any additional permissions your function needs (e.g. DynamoDB, S3).
