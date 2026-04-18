# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
