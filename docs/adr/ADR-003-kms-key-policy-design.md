# ADR-003: KMS Key Policy — Four-Statement Split and Extensibility via Variables

## Status
Accepted

## Context
KMS key policies conflate two distinct privilege classes that IAM separates elsewhere:

- **Key management** — operational actions: describe, rotate, schedule deletion, tag.
- **Permissions management** — actions that change who can use or manage the key: `kms:PutKeyPolicy`, `kms:CreateGrant`, `kms:RevokeGrant`.

Checkov rule `CKV_AWS_109` flags any policy that grants permissions-management actions without a constraining condition (e.g. `kms:CallerAccount`). Mixing permissions-management actions into a broader operational statement forces the condition onto all actions in that statement, which is either overly restrictive or requires duplicating the statement.

KMS key policies also require `"Resource": "*"` — the KMS service evaluates the policy only in the context of the key it is attached to, so `"*"` is effectively scoped to that key. The key ARN is unavailable at plan time (the policy must exist before the key is created), making explicit ARN references impossible. This triggers Checkov rule `CKV_AWS_356`.

The module must also support caller-specific grants (e.g. IAM roles, additional service principals) without requiring callers to fork the module or pass raw JSON.

## Decision
The key policy is split into four statements:

1. **`RootKeyManagement`** — grants operational key-management actions to the root account. Annotated `checkov:skip=CKV_AWS_356` because `"*"` is key-scoped.
2. **`RootPermissionsManagement`** — grants `kms:PutKeyPolicy`, `kms:CreateGrant`, `kms:RevokeGrant` to the root account, conditioned on `kms:CallerAccount`. Isolated so the `CKV_AWS_109` condition applies narrowly. Annotated `checkov:skip=CKV_AWS_356`.
3. **`AllowServicePrincipals`** — emitted via a `dynamic` block only when `var.service_principals` is non-empty. Grants encrypt/decrypt/generate-data-key actions to listed AWS service principals (e.g. `logs.us-east-1.amazonaws.com`, `lambda.amazonaws.com`).
4. **Additional statements** — each element of `var.additional_policy_statements` is rendered into a full statement via a `dynamic` block. Callers supply `actions`, optional `principals`, `conditions`, `sid`, `effect`, `resources`, etc.

`prevent_destroy = true` is set on the key resource.

## Alternatives Considered

**Single statement for all root actions** — Combining key-management and permissions-management actions into one statement requires applying the `kms:CallerAccount` condition to all of them, which is unnecessarily restrictive for operational actions, or omitting it, which triggers `CKV_AWS_109`. The split makes the privilege boundary explicit and satisfies the Checkov rule without suppression.

**Accept raw policy JSON** — Passing a complete policy JSON string gives callers full control but loses the safety guarantees of the root statements. A caller could accidentally omit the root account, locking the key. The variable-based extension model keeps the root statements unconditional.

**Separate module for each key type** — Different services need different service principals and grants, but the policy structure is identical. A single parameterized module with `service_principals` and `additional_policy_statements` covers all cases without duplication.

**Explicit ARN in `Resource`** — The key ARN is not available at plan time (chicken-and-egg: the policy is an argument to the key resource). `"*"` is the only viable option; the KMS service scopes it to the key being evaluated.

## Consequences
- The root account statements (`RootKeyManagement`, `RootPermissionsManagement`) are always present and cannot be removed via variables. This prevents key lockout.
- `prevent_destroy = true` on the key resource means removal requires a manual state edit — intentional friction against accidental deletion.
- Callers must not pass `kms:PutKeyPolicy` in `additional_policy_statements` without a `kms:CallerAccount` condition; doing so would allow any listed principal to replace the key policy.
- `CKV_AWS_109` and `CKV_AWS_356` are suppressed at the statement level with inline comments. Any reviewer seeing these suppressions should check the `kms:CallerAccount` condition on `RootPermissionsManagement` and the key-scoped semantics of `"*"` in KMS policies.
