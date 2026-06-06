/**
 * Per-app secrets footprint in a central "vault" AWS account.
 *
 * Instantiate once per (app, env). Creates a dedicated cross-account reader IAM
 * role scoped to that app's secrets only (by path prefix, convention "<app>/<env>",
 * e.g. appw/prod/*), plus — optionally — the Secrets Manager secret containers.
 *
 * App accounts (B, C, D) assume *their own* role (not a shared one) to fetch secrets.
 * The role's permission policy grants secretsmanager:GetSecretValue on
 * "<path_prefix>/*", so it can never read another app's secrets. Secrets use the
 * AWS-managed key (aws/secretsmanager); decryption is same-account (the read happens
 * under this role, inside the vault account), so no customer-managed KMS key or
 * cross-account kms:Decrypt grant is required.
 *
 * This module deliberately manages only secret *containers* and IAM — never secret
 * *values*. Plaintext therefore never lands in Terraform state. Put values in
 * out-of-band, e.g. `aws secretsmanager put-secret-value --secret-string file://...`.
 *
 * Pair with modules/secrets_consumer in each app account to grant the app's
 * workload role sts:AssumeRole on the reader_role_arn output here.
 */

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  # Resource-name base: derived from path_prefix ("appw/prod" -> "appw-prod") unless
  # the caller overrides it. Names the reader role and its inline policy, so they can
  # never drift from the prefix. App/Environment come from the "<app>/<env>" segments
  # for clean cost-allocation tags (Environment omitted when there's no env segment).
  name = coalesce(var.name, replace(var.path_prefix, "/", "-"))
  app  = split("/", var.path_prefix)[0]
  env  = try(split("/", var.path_prefix)[1], null)

  tags = merge(
    var.tags,
    { App = local.app },
    local.env == null ? {} : { Environment = local.env },
  )

  # Secrets Manager ARNs carry a random 6-char suffix, so scope by name prefix with
  # a trailing wildcard: every secret under "<path_prefix>/" matches, including ones
  # created later out-of-band.
  secret_arn_wildcard = "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${var.path_prefix}/*"

  # Built with jsonencode (not aws_iam_policy_document) so the documents are known at
  # plan time and assertable under mock providers in the test suite.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      merge(
        {
          Sid       = "TrustedAppAccounts"
          Effect    = "Allow"
          Principal = { AWS = var.trusted_principals }
          Action    = "sts:AssumeRole"
        },
        var.external_id == null ? {} : {
          Condition = { StringEquals = { "sts:ExternalId" = var.external_id } }
        }
      )
    ]
  })

  read_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "ReadAppSecrets"
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds",
      ]
      Resource = local.secret_arn_wildcard
    }]
  })
}

# --- Secret containers (optional) ---

resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name                    = "${var.path_prefix}/${each.key}"
  description             = each.value.description
  recovery_window_in_days = var.recovery_window_days
  tags                    = local.tags
}

# --- Cross-account reader role (one per app) ---

resource "aws_iam_role" "reader" {
  name                 = "${local.name}-secrets-reader"
  assume_role_policy   = local.assume_role_policy
  max_session_duration = var.max_session_duration
  tags                 = local.tags

  lifecycle {
    # IAM role names cap at 64 chars. Fail at plan with a clear message rather than
    # letting AWS reject the apply. (Variable validation can't see the derived local
    # before Terraform 1.9, so guard it here.)
    precondition {
      condition     = length("${local.name}-secrets-reader") <= 64
      error_message = "Derived role name \"${local.name}-secrets-reader\" is ${length("${local.name}-secrets-reader")} chars, over IAM's 64-char limit. Shorten path_prefix or pass a shorter name."
    }
  }
}

resource "aws_iam_role_policy" "read" {
  name   = "${local.name}-secrets-read"
  role   = aws_iam_role.reader.id
  policy = local.read_policy
}
