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
    region         = data.aws_region.current.region
    dynamodb_table = local.table_name
    encrypt        = true
  }
}
