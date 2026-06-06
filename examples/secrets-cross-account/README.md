# secrets-cross-account

Wires `secrets_vault` (central vault account) and `secrets_consumer` (app account) into the
centralized-secrets pattern, using a Cloudflare API token for "App W" as the worked example.

Secrets follow the app-first house convention **`<app>/<env>/<secret>`** (e.g.
`appw/prod/cloudflare-api-token`). App-first keeps an app's secrets grouped together and makes an
app-wide grant a single `appw/*` wildcard. There's one vault instance **per `(app, env)`** — each
with its own reader role and trusted principals — so a compromised staging role can never read
`appw/prod/*`.

## What this creates

| Module | Account | Purpose |
|---|---|---|
| `appw_prod_vault` (`secrets_vault`) | vault (default provider) | App W prod containers under `appw/prod/*` + a reader role scoped to that prefix |
| `appw_staging_vault` (`secrets_vault`) | vault (default provider) | App W staging containers under `appw/staging/*` + a reader role scoped to that prefix |
| `appw_prod_access` (`secrets_consumer`) | prod app (`aws.app` provider) | IAM policy granting App W's prod workload role `sts:AssumeRole` on the prod reader role |

The staging account mirrors `appw_prod_access` exactly (same module, a provider pointed at the
staging account, `vault_role_arns = [module.appw_staging_vault.reader_role_arn]`); it's omitted from
the example to keep it to two providers.

## Usage

```hcl
module "appw_secrets" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//examples/secrets-cross-account?ref=v1.6.0"

  prod_account_id        = "222222222222"
  staging_account_id     = "333333333333"
  app_workload_role_name = "appw-workload"

  tags = { project = "appw" }
}
```

## Key wiring

- `secrets_vault.reader_role_arn` → `secrets_consumer.vault_role_arns` — the app may assume its reader role
- `trusted_principals` → the matching env's app account root — only that env's account can assume its role
- Each reader role is scoped to `appw/<env>/*`, so App W can read its own env's secrets (and any future
  one under that prefix), never another app's or another env's

## Adding the secret value (out-of-band)

Terraform creates the **container** only — it never manages secret **values**, so plaintext never
lands in state. After `terraform apply`, put the token in from the vault account. The CLI reads the
value from a locked-down temp file so it never appears in your shell history or in `ps`:

```bash
umask 077
tmp=$(mktemp)
cat > "$tmp"          # paste the Cloudflare token, then Ctrl-D
aws secretsmanager put-secret-value \
  --secret-id appw/prod/cloudflare-api-token \
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
