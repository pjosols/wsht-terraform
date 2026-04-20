/**
 * Provision an AWS Organizations member account with SSO assignments.
 *
 * Creates a member account under the organization and assigns one or more
 * SSO principals (users or groups) to the account with specified permission sets.
 */

resource "aws_organizations_account" "this" {
  name                       = var.account_name
  email                      = var.email
  parent_id                  = var.parent_id
  iam_user_access_to_billing = var.iam_user_access_to_billing
  tags                       = var.tags

  lifecycle {
    prevent_destroy = true
    # iam_user_access_to_billing is write-once at account creation; AWS ignores
    # updates. Ignore to prevent spurious destroy+recreate on imported accounts.
    ignore_changes = [iam_user_access_to_billing]
  }
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = {
    for a in var.assignments : "${a.principal_id}/${a.permission_set_arn}" => a
  }

  instance_arn       = var.sso_instance_arn
  target_id          = aws_organizations_account.this.id
  target_type        = "AWS_ACCOUNT"
  permission_set_arn = each.value.permission_set_arn
  principal_id       = each.value.principal_id
  principal_type     = each.value.principal_type
}
