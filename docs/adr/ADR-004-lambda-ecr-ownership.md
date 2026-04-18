# ADR-004: Lambda Container Module — ECR Repository Ownership and Image URI Lifecycle

## Status
Accepted

## Context
The `lambda_container` module deploys container-image Lambdas. Every such Lambda requires an ECR repository. Two safety properties must be enforced on every repository:

- **Image scanning** (`scan_on_push = true`) — detects vulnerabilities at push time.
- **Lifecycle policy** — expires old images to prevent unbounded storage growth and accumulation of vulnerable images.

`image_tag_mutability = "IMMUTABLE"` prevents tags from being silently overwritten, which would make deployments non-deterministic.

After initial deployment, the CI/CD pipeline — not Terraform — is responsible for deploying new images. It calls `aws lambda update-function-code` directly after pushing to ECR. If Terraform managed `image_uri` across all applies, every `terraform apply` would revert the function to the image URI recorded in state, undoing the CI deployment.

The Lambda function, its ECR repository, and its CloudWatch log group all store sensitive data and should share a single customer-managed KMS key. Using separate keys per resource would require three key policies with no security benefit.

## Decision
The module creates and owns the ECR repository. `scan_on_push = true`, `image_tag_mutability = "IMMUTABLE"`, and a lifecycle policy (`tagStatus = "any"`, keep last `var.ecr_keep_image_count` images, default 5) are always enforced. Callers cannot supply a pre-existing repository.

`image_uri` is declared with `lifecycle { ignore_changes = [image_uri] }`. It is required at module instantiation so Terraform can create the function with a valid image on first apply, but all subsequent image updates go through `aws lambda update-function-code` outside Terraform.

A single `kms_key_arn` is applied to the ECR repository (`encryption_configuration.kms_key`), the CloudWatch log group (`kms_key_id`), and the Lambda function (`kms_key_arn` for environment variable encryption). It defaults to `null`, falling back to AWS-managed encryption.

The base IAM policy (`aws_iam_role_policy.logs_and_ecr`) grants the minimum permissions every image-based Lambda needs: CloudWatch Logs write access scoped to the module's log group ARN, ECR image pull actions scoped to the module's repository ARN, and `ecr:GetAuthorizationToken` with `Resource: "*"` (AWS does not support resource-level restrictions for this action). Caller-specific permissions go in `iam_policy_json`, attached as a separate inline policy.

## Alternatives Considered

**Accept a caller-supplied ECR repository ARN** — Callers could create the repository separately and pass its ARN. This removes the module's ability to enforce `scan_on_push`, `IMMUTABLE` tags, and a lifecycle policy. A caller-supplied repository might omit any of these. Owning the repository is the only way to guarantee the safety properties unconditionally.

**Manage `image_uri` in Terraform** — If Terraform owned `image_uri`, every `terraform apply` would revert the function to the state-recorded URI, undoing CI deployments. The CI pipeline would need to update Terraform state after every push, coupling the deployment pipeline to Terraform. `ignore_changes` decouples them cleanly.

**Separate KMS keys per resource** — Three keys would require three key policies, each granting the relevant service principal. There is no security benefit to isolation here — all three resources belong to the same Lambda workload. One key with one policy is simpler and auditable.

**Include caller permissions in the base policy** — Merging caller-specific grants into the base policy makes the base policy variable and harder to audit. A separate `iam_policy_json` attachment keeps the base policy stable.

## Consequences
- `image_uri` is only used on first apply. All subsequent image deployments must go through `aws lambda update-function-code`, not `terraform apply`.
- For production workloads, supply a customer-managed `kms_key_arn`. The key policy must grant `ecr.amazonaws.com`, `logs.<region>.amazonaws.com`, and `lambda.amazonaws.com` the `kms:GenerateDataKey` and `kms:Decrypt` actions.
- `ecr:GetAuthorizationToken` requires `Resource: "*"`. This is unavoidable — AWS does not support resource-level restrictions for this action. The token is short-lived (12 hours) and scoped to the ECR service only.
- Set `dead_letter_arn` for any async invocation path (SNS, S3 events, EventBridge, SQS). Without it, failed async invocations are silently discarded after Lambda's built-in retry attempts. For synchronous invocations (API Gateway, direct `Invoke`), the caller receives the error directly and a dead-letter config has no effect.
- VPC-attached Lambdas cannot reach ECR or CloudWatch Logs over the public internet. VPC endpoints for `ecr.api`, `ecr.dkr`, `logs`, and `s3` (for ECR layer downloads) are required, or traffic must route through a NAT gateway.
