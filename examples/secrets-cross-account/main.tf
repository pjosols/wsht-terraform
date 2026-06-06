# Vault account (default provider): App W's secret containers + a cross-account
# reader role scoped to prod/appw/*. Secret *values* are never managed here — see
# the secret_set_command output for how to put them in out-of-band.
module "appw_vault" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/secrets_vault?ref=v1.5.0"

  name        = "appw"
  path_prefix = "prod/appw"

  trusted_principals = ["arn:aws:iam::${var.app_account_id}:root"]
  external_id        = "appw-prod"

  secrets = {
    cloudflare-api-token = { description = "Cloudflare scoped API token for App W" }
  }

  tags = var.tags
}

# App W account: grant the workload role permission to assume the reader role.
module "appw_access" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/secrets_consumer?ref=v1.5.0"

  providers = {
    aws = aws.app
  }

  name            = "appw"
  vault_role_arns = [module.appw_vault.reader_role_arn]

  attach_to_role_names = [var.app_workload_role_name]

  tags = var.tags
}

output "reader_role_arn" {
  description = "Reader role App W's workload assumes to fetch its secrets."
  value       = module.appw_vault.reader_role_arn
}

output "secret_set_command" {
  description = "Run this from the vault account to put the Cloudflare token in out-of-band — values are never managed by Terraform."
  value       = "umask 077; tmp=$(mktemp); cat > \"$tmp\"; aws secretsmanager put-secret-value --secret-id prod/appw/cloudflare-api-token --secret-string \"file://$tmp\"; rm -P \"$tmp\""
}
