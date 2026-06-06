output "instance_id" {
  description = "EC2 instance ID (use with SSM Session Manager / send-command)."
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IPv4 — point the origin DNS record (e.g. origin.example.com) at this."
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IPv4."
  value       = aws_instance.this.private_ip
}

output "security_group_id" {
  description = "Origin security group ID."
  value       = aws_security_group.this.id
}

output "iam_role_name" {
  description = "Instance role name (attach extra policies if needed)."
  value       = aws_iam_role.this.name
}

output "iam_role_arn" {
  description = "Instance role ARN."
  value       = aws_iam_role.this.arn
}
