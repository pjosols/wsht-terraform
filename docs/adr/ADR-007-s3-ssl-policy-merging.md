# ADR-007: S3 Bucket — Unconditional SSL Enforcement and Policy Merging

## Status
Accepted

## Context
The `s3_bucket` module must enforce TLS on all S3 traffic unconditionally. This is a non-negotiable security default — every bucket produced by the module must deny non-SSL requests regardless of whether the caller supplies a custom bucket policy.

Many callers also need a custom policy (e.g. a CloudFront OAC grant, cross-account access). If the module simply overwrites the caller's policy with the SSL-only policy, the caller's grants are lost. If the module applies the caller's policy as-is, the SSL enforcement can be omitted by accident.

The two requirements — unconditional SSL enforcement and support for caller-supplied grants — must be satisfied simultaneously without requiring callers to include the `DenyNonSSL` statement themselves.

## Decision
The module always appends a `DenyNonSSL` statement to the bucket policy. When `policy_json` is `null`, the policy is a minimal document containing only that statement. When `policy_json` is provided, the module merges the SSL deny statement into it:

```hcl
merged_policy = jsonencode(merge(
  decoded_policy,
  {
    Statement = concat(
      lookup(decoded_policy, "Statement", []),
      [ssl_deny_statement]
    )
  }
))
```

`merge()` preserves all top-level keys from the caller's policy (`Version`, `Id`, etc.) while replacing `Statement` with the concatenated list. The SSL deny statement is always appended last.

The `DenyNonSSL` statement denies all `s3:*` actions on the bucket and its objects when `aws:SecureTransport` is `false`, with `Principal = "*"`.

A variable validation rule requires that any provided `policy_json` contains a top-level `Statement` key.

## Alternatives Considered

**Require callers to include `DenyNonSSL` in their policy** — This makes SSL enforcement opt-in. A caller who forgets the statement ships a bucket that accepts unencrypted traffic. The unconditional merge removes this failure mode.

**Separate `ssl_policy` resource alongside the caller's policy** — S3 buckets accept only one bucket policy. Two `aws_s3_bucket_policy` resources on the same bucket would conflict. Merging into a single policy document is the only viable approach.

**Prepend instead of append the SSL deny statement** — Statement order in S3 bucket policies does not affect evaluation (S3 evaluates all statements and takes the most restrictive result). Appending is arbitrary but consistent; it keeps the caller's statements first for readability.

**Accept the SSL statement as a variable that callers can override** — Making the SSL deny statement configurable would allow callers to weaken or remove it. The security default must be unconditional.

## Consequences
- Callers must not include a `DenyNonSSL` statement in `policy_json` — it will be duplicated. The module always appends it unconditionally.
- The `Version` field is optional in `policy_json`. If omitted, the merged output also omits it; AWS defaults to `2012-10-17`.
- Any caller-supplied policy must include a top-level `Statement` key. The variable validation enforces this at plan time.
- The SSL deny statement uses `Principal = "*"` and `Action = "s3:*"`. This is intentionally broad — it catches all non-SSL access regardless of the caller's identity.
