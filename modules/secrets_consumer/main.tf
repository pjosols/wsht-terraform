/**
 * App-account side of centralized secrets access.
 *
 * Runs in an app account (B, C, D). Produces an IAM policy granting sts:AssumeRole
 * on the per-app reader role(s) exposed by modules/secrets_vault in the central
 * vault account. Attach it to the app's workload role (Lambda/EC2 instance/ECS task
 * role); the workload then assumes the reader role and calls
 * secretsmanager:GetSecretValue on its own secrets.
 *
 * Optionally attaches the policy to existing role(s) via attach_to_role_names; either
 * way the policy ARN and JSON are exported for the caller to wire up.
 */

locals {
  # jsonencode (not aws_iam_policy_document) so the document is known at plan time and
  # assertable under mock providers in the test suite.
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "AssumeVaultReaderRoles"
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = var.vault_role_arns
    }]
  })
}

resource "aws_iam_policy" "this" {
  name        = "${var.name}-secrets-access"
  description = "Assume the central vault reader role(s) to fetch ${var.name} secrets."
  policy      = local.policy_json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.attach_to_role_names)

  role       = each.value
  policy_arn = aws_iam_policy.this.arn
}
