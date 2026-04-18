/**
 * Provision KMS key with alias, rotation, and deletion protection.
 *
 * Creates customer-managed KMS key with automatic key rotation enabled,
 * deletion protection, and alias. Grants root account full key management
 * permissions and caller-supplied principals read/decrypt access.
 */

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "this" {
  statement {
    sid    = "RootKeyManagement"
    effect = "Allow"
    # Root account key management — excludes permissions management actions (handled separately).
    actions = [
      "kms:CreateAlias",
      "kms:CreateCustomKeyStore",
      "kms:CreateKey",
      "kms:DescribeCustomKeyStores",
      "kms:DescribeKey",
      "kms:EnableKey",
      "kms:EnableKeyRotation",
      "kms:ListAliases",
      "kms:ListGrants",
      "kms:ListKeyPolicies",
      "kms:ListKeyRotations",
      "kms:ListKeys",
      "kms:ListResourceTags",
      "kms:ListRetirableGrants",
      "kms:UpdateAlias",
      "kms:UpdateCustomKeyStore",
      "kms:UpdateKeyDescription",
      "kms:UpdatePrimaryRegion",
      "kms:DisableKey",
      "kms:DisableKeyRotation",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:GetParametersForImport",
      "kms:GetPublicKey",
      "kms:DeleteAlias",
      "kms:DeleteCustomKeyStore",
      "kms:DeleteImportedKeyMaterial",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    # checkov:skip=CKV_AWS_356: In a KMS key policy, "*" refers to the key itself,
    # not all KMS keys. The key ARN is unavailable at policy-document evaluation time
    # (chicken-and-egg), so resource-level scoping is not possible here.
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "RootPermissionsManagement"
    effect = "Allow"
    # Permissions management actions for root — constrained to this account to satisfy
    # CKV_AWS_109. kms:PutKeyPolicy is required to prevent key lockout; kms:CreateGrant
    # and kms:RevokeGrant allow root to manage grants on behalf of services.
    actions = [
      "kms:CreateGrant",
      "kms:PutKeyPolicy",
      "kms:RevokeGrant",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    # checkov:skip=CKV_AWS_356: Same rationale — "*" in a KMS key policy is scoped to
    # this key by the KMS service; the key ARN is not available at plan time.
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  dynamic "statement" {
    for_each = length(var.service_principals) > 0 ? [1] : []
    content {
      sid    = "AllowServicePrincipals"
      effect = "Allow"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*",
      ]
      principals {
        type        = "Service"
        identifiers = var.service_principals
      }
      # checkov:skip=CKV_AWS_356: Same rationale — "*" in a KMS key policy is scoped
      # to this key by the KMS service; the key ARN is not available at plan time.
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.additional_policy_statements
    content {
      sid           = lookup(statement.value, "sid", null)
      effect        = lookup(statement.value, "effect", "Allow")
      actions       = statement.value.actions
      not_actions   = lookup(statement.value, "not_actions", null)
      resources     = lookup(statement.value, "resources", ["*"])
      not_resources = lookup(statement.value, "not_resources", null)

      dynamic "principals" {
        for_each = statement.value.principals != null ? statement.value.principals : []
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = statement.value.conditions != null ? statement.value.conditions : []
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_kms_key" "this" {
  description              = var.description
  deletion_window_in_days  = 30
  enable_key_rotation      = true
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage                = "ENCRYPT_DECRYPT"
  policy                   = data.aws_iam_policy_document.this.json
  tags                     = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "this" {
  name          = var.alias_prefix != "" ? "alias/${var.alias_prefix}-${var.name}" : "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}
