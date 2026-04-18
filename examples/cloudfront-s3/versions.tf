terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.41"
    }
  }
  required_version = ">= 1.6"
}

provider "aws" {
  region = "us-east-1"
}

# CloudFront requires ACM certificates in us-east-1.
# The cloudfront module uses this alias when create_certificate = true.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
