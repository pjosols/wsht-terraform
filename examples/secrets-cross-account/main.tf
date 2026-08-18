# Centralized secrets, app-first convention: <app>/<env>/<secret>.
#
# One vault instance per (app, env) — each gets its own reader role and trusted
# principals, so a compromised staging role can never read appw/prod/* secrets.
# Both vault instances live in the same vault account (default provider); the
# consumer side runs in each app's own account.

# --- Vault account: App W, prod ---
module "appw_prod_vault" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/secrets_vault?ref=v1.10.1"

  # Role name derives from path_prefix -> "appw-prod-secrets-reader" (no `name` needed).
  path_prefix = "appw/prod"

  trusted_principals = ["arn:aws:iam::${var.prod_account_id}:root"]
  external_id        = "appw-prod"

  secrets = {
    cloudflare-api-token = { description = "Cloudflare scoped API token for App W (prod)" }
  }

  tags = var.tags
}

# --- Vault account: App W, staging ---
module "appw_staging_vault" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/secrets_vault?ref=v1.10.1"

  # Role name derives from path_prefix -> "appw-staging-secrets-reader".
  path_prefix = "appw/staging"

  trusted_principals = ["arn:aws:iam::${var.staging_account_id}:root"]
  external_id        = "appw-staging"

  secrets = {
    cloudflare-api-token = { description = "Cloudflare scoped API token for App W (staging)" }
  }

  tags = var.tags
}

# --- App W prod account: let the workload assume the prod reader role ---
module "appw_prod_access" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/secrets_consumer?ref=v1.10.1"

  providers = {
    aws = aws.app
  }

  name            = "appw"
  vault_role_arns = [module.appw_prod_vault.reader_role_arn]

  attach_to_role_names = [var.app_workload_role_name]

  tags = var.tags
}

# The staging account mirrors appw_prod_access exactly — same module, a provider
# pointed at the staging account, and vault_role_arns = [module.appw_staging_vault.reader_role_arn].
# Omitted here to keep the example to two providers.

output "prod_reader_role_arn" {
  description = "Reader role App W's prod workload assumes to fetch its secrets."
  value       = module.appw_prod_vault.reader_role_arn
}

output "staging_reader_role_arn" {
  description = "Reader role App W's staging workload assumes to fetch its secrets."
  value       = module.appw_staging_vault.reader_role_arn
}

output "secret_set_command" {
  description = "Run this from the vault account to put the prod Cloudflare token in out-of-band — values are never managed by Terraform."
  value       = "umask 077; tmp=$(mktemp); cat > \"$tmp\"; aws secretsmanager put-secret-value --secret-id appw/prod/cloudflare-api-token --secret-string \"file://$tmp\"; rm -P \"$tmp\""
}
