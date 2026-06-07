/**
 * Public-subnet EC2 app server, sized for a small Dockerized service behind CloudFront.
 *
 * Runs Docker (for the app's docker-compose: an API container from ECR + Caddy terminating
 * origin TLS). Designed as a CloudFront *custom origin*: the security group admits :443 only
 * from CloudFront's origin-facing managed prefix list, and TLS is terminated on the box
 * (Caddy/Let's Encrypt) so the CloudFront→origin leg is encrypted end-to-end. The instance
 * has a public IP for internet egress (ECR/Docker/ACME/AWS APIs) — no NAT gateway.
 *
 * Access is via SSM Session Manager (no SSH key, no inbound :22). AWS access for containers
 * is via the instance role over IMDS, with the metadata hop limit raised to 2 so Docker
 * containers can reach it. App-specific permissions come from var.additional_iam_policy_json.
 */

data "aws_region" "current" {}

# Latest Amazon Linux 2023 (arm64/Graviton) AMI.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

# CloudFront's origin-facing IP ranges — the only source allowed to reach the origin.
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# --- IAM: instance role ---

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-ec2"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

# SSM Session Manager (shell + port-forward, no SSH).
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ECR pull + read of the configured SSM parameters (and decrypt of SecureStrings).
data "aws_iam_policy_document" "base" {
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid = "EcrPull"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = length(var.ecr_repository_arns) > 0 ? var.ecr_repository_arns : ["*"]
  }

  dynamic "statement" {
    for_each = length(var.readable_ssm_parameter_arns) > 0 ? [1] : []
    content {
      sid       = "SsmRead"
      actions   = ["ssm:GetParameter", "ssm:GetParameters"]
      resources = var.readable_ssm_parameter_arns
    }
  }

  # Decrypt SecureString parameters with the SSM-managed key (scoped to the SSM service).
  dynamic "statement" {
    for_each = length(var.readable_ssm_parameter_arns) > 0 ? [1] : []
    content {
      sid       = "SsmDecrypt"
      actions   = ["kms:Decrypt"]
      resources = ["*"]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["ssm.${data.aws_region.current.region}.amazonaws.com"]
      }
    }
  }
}

resource "aws_iam_role_policy" "base" {
  name   = "${var.name}-base"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.base.json
}

# App-specific permissions (S3 Vectors, DynamoDB, Bedrock, …) supplied by the caller.
resource "aws_iam_role_policy" "app" {
  count  = var.additional_iam_policy_json == null ? 0 : 1
  name   = "${var.name}-app"
  role   = aws_iam_role.this.id
  policy = var.additional_iam_policy_json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-ec2"
  role = aws_iam_role.this.name
  tags = var.tags
}

# --- Security group: :443 from CloudFront only ---

resource "aws_security_group" "this" {
  name        = "${var.name}-origin"
  description = "${var.name} origin - HTTPS from CloudFront only"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "https_from_cloudfront" {
  security_group_id = aws_security_group.this.id
  description       = "HTTPS from CloudFront origin-facing ranges"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "All egress (ECR, Docker, ACME, AWS APIs)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# --- Instance ---

resource "aws_instance" "this" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.this.name
  vpc_security_group_ids      = [aws_security_group.this.id]
  user_data                   = local.user_data

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 2          # so Docker containers can reach instance creds
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, { Name = var.name })
}

# Stable public IP for the origin. The origin DNS record (e.g. origin.example.com) points
# here, so it must survive a stop/start (the auto-assigned public IP would not). Both app_server
# consumers want this, so the module owns it; opt out with assign_elastic_ip = false.
resource "aws_eip" "this" {
  count    = var.assign_elastic_ip ? 1 : 0
  instance = aws_instance.this.id
  domain   = "vpc"
  tags     = merge(var.tags, { Name = var.name })
}

locals {
  # Bring up Docker + the compose plugin; SSM agent is preinstalled on AL2023. The actual
  # app deploy (copy compose/Caddyfile, docker compose up) is driven by CI over SSM.
  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-aarch64" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
  EOT
}
