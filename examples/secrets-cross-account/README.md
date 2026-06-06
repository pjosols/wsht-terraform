# secrets-cross-account

Wires `secrets_vault` (central vault account) and `secrets_consumer` (app account) into the
centralized-secrets pattern, using a Cloudflare API token for "App W" as the worked example.

## What this creates

| Module | Account | Purpose |
|---|---|---|
| `secrets_vault` | vault (default provider) | App W's secret containers under `prod/appw/*` + a cross-account reader IAM role scoped to that prefix |
| `secrets_consumer` | app (`aws.app` provider) | IAM policy granting App W's workload role `sts:AssumeRole` on the reader role |

## Usage

```hcl
module "appw_secrets" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//examples/secrets-cross-account?ref=v1.5.0"

  app_account_id         = "222222222222"
  app_workload_role_name = "appw-workload"

  tags = { project = "appw" }
}
```

## Key wiring

- `secrets_vault.reader_role_arn` → `secrets_consumer.vault_role_arns` — the app may assume the reader role
- `trusted_principals` on the vault role → the app account root — only App W's account can assume it
- The reader role is scoped to `prod/appw/*`, so App W can read this and any future App W secret, never another app's

## Adding the secret value (out-of-band)

Terraform creates the **container** only — it never manages secret **values**, so plaintext never
lands in state. After `terraform apply`, put the token in from the vault account. The CLI reads the
value from a locked-down temp file so it never appears in your shell history or in `ps`:

```bash
umask 077
tmp=$(mktemp)
cat > "$tmp"          # paste the Cloudflare token, then Ctrl-D
aws secretsmanager put-secret-value \
  --secret-id prod/appw/cloudflare-api-token \
  --secret-string "file://$tmp"
rm -P "$tmp"
```

The `secret_set_command` output prints this one-liner. **Rotation** is the same command again — a new
`AWSCURRENT` version, no Terraform run, no drift.

## Notes

- No backend is configured — callers supply their own `terraform { backend ... }` block.
- The two `provider "aws"` blocks in `versions.tf` should assume a role into the vault account
  (default) and the app account (`aws.app`) respectively; uncomment the `assume_role` blocks.
- Prefer a scoped Cloudflare API **Token** over the legacy global API Key — least privilege, and
  revocable in isolation if leaked.
