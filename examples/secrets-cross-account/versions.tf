terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.41"
    }
  }
  required_version = ">= 1.6"
}

# Vault account (default provider). In real use, assume a role into the
# central secrets-vault account.
provider "aws" {
  region = "us-east-1"
  # assume_role { role_arn = "arn:aws:iam::<vault-account-id>:role/terraform" }
}

# App W account. In real use, assume a role into the app account.
provider "aws" {
  alias  = "app"
  region = "us-east-1"
  # assume_role { role_arn = "arn:aws:iam::<app-account-id>:role/terraform" }
}
