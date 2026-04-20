# New Modules Spec

Two new modules to support repeatable org-level account provisioning.

---

## 1. `modules/org_account`

### Purpose

Creates an AWS Organizations member account and assigns one or more SSO users to it with specified permission sets. Used from a central `org-management` root config to provision every project account in a single `terraform apply`.

### Resources

| Resource | Description |
|---|---|
| `aws_organizations_account` | The member account |
| `aws_sso_admin_account_assignment` (×N) | One per `{user, permission_set}` pair |

### Variables

```hcl
variable "account_name" {
  description = "Display name for the AWS Organizations account."
  type        = string
}

variable "email" {
  description = "Unique email address for the account root user."
  type        = string
}

variable "parent_id" {
  description = "Organizations OU or root ID to place the account in. Defaults to org root."
  type        = string
  default     = null
}

variable "iam_user_access_to_billing" {
  description = "Allow IAM users to access billing. ALLOW or DENY."
  type        = string
  default     = "DENY"
}

variable "sso_instance_arn" {
  description = "ARN of the IAM Identity Center instance."
  type        = string
}

variable "assignments" {
  description = "List of {principal_id, principal_type, permission_set_arn} to assign to this account."
  type = list(object({
    principal_id        = string
    principal_type      = string  # "USER" or "GROUP"
    permission_set_arn  = string
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the Organizations account resource."
  type        = map(string)
  default     = {}
}
```

### Outputs

```hcl
output "account_id" {
  description = "The AWS account ID of the created account."
  value       = aws_organizations_account.this.id
}

output "account_arn" {
  description = "The ARN of the created account."
  value       = aws_organizations_account.this.arn
}
```

### Notes

- `aws_organizations_account` does not support deletion via Terraform (AWS requires manual account closure). Add a `lifecycle { prevent_destroy = true }` block.
- The `assignments` list drives a `for_each` on `aws_sso_admin_account_assignment`. Use a map key of `"${principal_id}/${permission_set_arn}"` to make keys stable.
- No `aws_iam_identity_center_*` data sources needed — caller passes ARNs directly (they're stable and known from the SSO instance).
- Provider: standard `aws` provider, no alias needed. The org management account has permissions to call both `organizations:CreateAccount` and `sso-admin:CreateAccountAssignment`.

### Example usage (from org-management root)

```hcl
module "leachknives" {
  source = "git::https://github.com/pjosols/wsht-terraform.git//modules/org_account?ref=<sha>"

  account_name     = "leachknives-prod"
  email            = "aws+leachknives@wholeshoot.com"
  sso_instance_arn = local.sso_instance_arn

  assignments = [
    {
      principal_id       = local.paul_user_id
      principal_type     = "USER"
      permission_set_arn = local.admin_permission_set_arn
    },
    {
      principal_id       = local.paul_user_id
      principal_type     = "USER"
      permission_set_arn = local.poweruser_permission_set_arn
    },
  ]
}
```

---

## 2. `modules/tfstate_backend`

### Purpose

Provisions the S3 bucket and DynamoDB table used as a Terraform remote state backend for a project. Run once per project from the `org-management` account (or the project account itself) before the project's own Terraform is initialized.

### Resources

| Resource | Description |
|---|---|
| `aws_s3_bucket` (via `s3_bucket` module) | Versioned, encrypted, SSL-only state bucket |
| `aws_dynamodb_table` | State lock table with `LockID` hash key, PAY_PER_REQUEST billing |

### Variables

```hcl
variable "project" {
  description = "Project name. Used to derive bucket name (<project>-tfstate) and table name (<project>-tfstate-lock)."
  type        = string
}

variable "bucket_name" {
  description = "Override the default bucket name. Defaults to '<project>-tfstate'."
  type        = string
  default     = null
}

variable "table_name" {
  description = "Override the default DynamoDB table name. Defaults to '<project>-tfstate-lock'."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for S3 and DynamoDB encryption. If null, AES256/AWS-managed keys are used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
```

### Outputs

```hcl
output "bucket_name" {
  description = "Name of the S3 state bucket."
  value       = local.bucket_name
}

output "table_name" {
  description = "Name of the DynamoDB lock table."
  value       = local.table_name
}

output "backend_config" {
  description = "Ready-to-paste backend block values."
  value = {
    bucket         = local.bucket_name
    key            = "${var.project}/terraform.tfstate"
    region         = data.aws_region.current.name
    dynamodb_table = local.table_name
    encrypt        = true
  }
}
```

### Notes

- Use the existing `s3_bucket` module for the bucket (gets versioning, encryption, SSL-only policy, public access block for free).
- DynamoDB table: `hash_key = "LockID"`, `billing_mode = "PAY_PER_REQUEST"`, point-in-time recovery enabled, encryption with `SSESpecification` (AWS-managed or KMS if `kms_key_arn` provided).
- Add `lifecycle { prevent_destroy = true }` to both resources.
- `data "aws_region" "current" {}` to populate the backend config output.

### Example usage

```hcl
module "leachknives_backend" {
  source  = "git::https://github.com/pjosols/wsht-terraform.git//modules/tfstate_backend?ref=<sha>"
  project = "leachknives.com"
  tags    = { Project = "leachknives.com" }
}
```

Produces a backend block for `leachknives.com/terraform/versions.tf`:

```hcl
backend "s3" {
  bucket         = "leachknives.com-tfstate"
  key            = "leachknives.com/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "leachknives.com-tfstate-lock"
  encrypt        = true
}
```

---

## Module conventions (match existing modules)

- `versions.tf`: `required_version = ">= 1.6"`, `aws ~> 6.41`
- `main.tf`, `variables.tf`, `outputs.tf` — no other files
- File-level JSDoc comment block describing what the module creates
- `tests/<module_name>.tftest.hcl` with plan-only assertions covering: resource creation, output values, validation rejections
- No hardcoded region or account ID — use `data` sources or variables
