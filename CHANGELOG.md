# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.6.1] - 2026-06-06

### Added
- `secrets_vault`: plan-time precondition that the derived reader-role name fits IAM's 64-char limit, so an over-long `path_prefix`/`name` fails fast with a clear message instead of being rejected by AWS at apply

## [1.6.0] - 2026-06-06

### Changed
- `secrets_vault`: derive the reader-role and inline-policy names from `path_prefix` (e.g. `appw/prod` → `appw-prod-secrets-reader`) so they can't drift from the prefix or collide across `(app, env)` in a single vault account. `name` is now an optional override of the derived base (was required). `App` and `Environment` tags are derived from the `<app>/<env>` segments (Environment omitted when there's no env segment)
- `examples/secrets-cross-account`: drop the explicit `name` on the vault instances and rely on derivation

Backward compatible: callers still passing `name` keep the same role name (no replacement). Omitting `name` uses the derived name — if a previously-deployed role used a `name` that differs from the derived slug, omitting it renames (replaces) the IAM role.

## [1.5.1] - 2026-06-06

### Changed
- `secrets_vault`: document the app-first `<app>/<env>` path-prefix convention (e.g. `appw/prod`) — app's secrets group together and an app-wide grant is a single `appw/*` wildcard. No logic change; `path_prefix` remains free-form
- `examples/secrets-cross-account`: switch to the `<app>/<env>` convention and show the multi-env-per-app pattern (separate `appw/prod` and `appw/staging` vault instances, each with its own reader role and trusted principals)

## [1.5.0] - 2026-06-06

### Added
- `modules/secrets_vault`: per-app Secrets Manager containers and a cross-account reader IAM role scoped to the app's path prefix, for centralized secrets in a vault account. Manages containers and IAM only — never secret values — so plaintext never lands in state
- `modules/secrets_consumer`: app-account IAM policy granting the workload role `sts:AssumeRole` on the vault reader role(s)
- `examples/secrets-cross-account`: wires `secrets_vault` + `secrets_consumer` across two accounts (Cloudflare token for "App W" as the worked example)

## [1.4.1] - 2026-06-06

### Fixed
- `app_server`: ASCII-only security group description (AWS rejects non-ASCII `GroupDescription`)

## [1.4.0] - 2026-06-06

### Added
- `modules/app_server`: public-subnet EC2 CloudFront custom origin (Docker, SSM, no NAT gateway)

## [1.3.0] - 2026-06-04

### Added
- `modules/s3_vectors`: S3 Vectors vector bucket and index

### Changed
- `s3_bucket`: noncurrent-version expiration support

## [1.2.0] - 2026-06-01

### Added
- `modules/bedrock_kb_s3vectors`: S3 Vectors-backed Bedrock Knowledge Base with a CUSTOM data source for direct ingestion; FIXED_SIZE chunking (300 tokens, 20% overlap)
- `modules/ses_inbound`: SES domain identity and receipt rule set for S3 inbound email
- `s3_bucket`: `versioning_enabled` variable (default true; suspends versioning when false)

## [1.1.1] - 2026-04-20

### Fixed
- `org_account`: ignore `iam_user_access_to_billing` changes (write-once at account creation; prevents spurious diffs on imported accounts)

## [1.1.0] - 2026-04-20

### Added
- `modules/tfstate_backend`: S3 + DynamoDB for Terraform remote state with encryption and versioning
- `modules/org_account`: AWS Organizations member account with IAM Identity Center SSO assignments

## [1.0.0] - 2026-04-18

### Added
- 9 Terraform modules: lambda_container, s3_bucket, cloudfront, kms, monitoring, waf, acm, cognito, apigw
- Terraform test suite for all modules using mock providers (no live AWS required)
- Architecture Decision Records in `docs/adr/`
- Variable and output descriptions, module docstrings, and README for all modules

### Security
- Encryption at rest on all storage resources (KMS or AWS-managed)
- Public access blocked by default on S3
- TLS 1.2+ minimum on all endpoints
- IAM least-privilege with no wildcard actions except where explicitly justified
