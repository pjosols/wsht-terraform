terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.41"
      configuration_aliases = [aws.us_east_1]
    }
  }
  required_version = ">= 1.6"
}
