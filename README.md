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
| `modules/secrets_vault` | Vault-account side of centralized secrets: per-app Secrets Manager containers + a cross-account reader IAM role scoped to that app's path prefix. |
| `modules/secrets_consumer` | App-account side of centralized secrets: IAM policy granting the workload role `sts:AssumeRole` on the vault reader role(s). |
| `modules/app_server` | Public-subnet EC2 CloudFront custom origin (Docker, SSM access, Elastic IP, no NAT). Pinned AMI with explicit-only instance replacement. |
| `modules/bedrock_kb_s3vectors` | S3 Vectors-backed Bedrock Knowledge Base with a CUSTOM data source for direct ingestion. |
| `modules/s3_vectors` | S3 Vectors vector bucket and index. |
| `modules/ses_inbound` | SES domain identity and receipt rule set for S3 inbound email. |

## Requirements

All modules require Terraform >= 1.6 and `hashicorp/aws ~> 6.41`. CI runs Terraform 1.15.5.

## Usage

```hcl
module "api" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/lambda_container?ref=v1.10.1"

  name            = "my-api"
  image_uri       = "123456789.dkr.ecr.us-east-1.amazonaws.com/my-api:latest"
  iam_policy_json = data.aws_iam_policy_document.api.json
  timeout         = 30
  memory_size     = 256

  tags = { Project = "my-project" }
}
```

## Documentation

All modules include variable descriptions with types and defaults, and output
descriptions for every exported value. Non-obvious design choices are recorded
as Architecture Decision Records in `docs/adr/` — see `docs/adr/README.md`.
