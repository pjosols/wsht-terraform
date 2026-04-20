# wsht-terraform

Opinionated Terraform modules for AWS infrastructure. Encryption, least-privilege IAM, and secure defaults built in.

## Modules

| Module | Description |
|--------|-------------|
| `modules/lambda_container` | Lambda (container/ECR) + IAM + CloudWatch logs. Enforces arm64, X-Ray, immutable tags, DLQ support. |
| `modules/s3_bucket` | S3 bucket with public access block, encryption, versioning, SSL-only, multipart cleanup. |
| `modules/cloudfront` | CloudFront distribution with TLS 1.2+, security headers, OAC, optional WAF. |
| `modules/kms` | KMS key + alias with rotation enabled, deletion protection. |
| `modules/monitoring` | Per-Lambda CloudWatch alarms (errors, duration, throttles). |
| `modules/waf` | WAF Web ACL with rate limiting + AWS managed rule groups. |
| `modules/acm` | ACM certificate with DNS validation. |
| `modules/cognito` | Cognito user pool + client with password policy, MFA, token config. |
| `modules/apigw` | HTTP API Gateway (v2) with Lambda proxy integration, JWT/REQUEST authorizers, CORS, access logging, throttling. |
| `modules/tfstate_backend` | S3 + DynamoDB for Terraform remote state with encryption and versioning. |
| `modules/org_account` | AWS Organizations member account with IAM Identity Center SSO assignments. |

## Usage

```hcl
module "api" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/lambda_container?ref=v1.0.0"

  name            = "my-api"
  image_uri       = "123456789.dkr.ecr.us-east-1.amazonaws.com/my-api:latest"
  iam_policy_json = data.aws_iam_policy_document.api.json
  timeout         = 30
  memory_size     = 256

  tags = { Project = "my-project" }
}
```

## Documentation

All modules include:
- Variable descriptions with type and default values
- Output descriptions for all exported values
- Architecture Decision Records (ADRs) in `docs/adr/` for non-obvious design choices

See `docs/adr/README.md` for architectural decisions.
