# app_server

A small public-subnet EC2 app server to run a Dockerized service **as a CloudFront custom
origin**, with end-to-end TLS and no NAT.

- **EC2** (default `t4g.micro`, Graviton, AL2023 arm64) with Docker + the compose plugin.
- **Security group**: inbound `:443` from CloudFront's origin-facing managed prefix list
  only — nothing else. (TLS is terminated on the box, e.g. by Caddy, so the
  CloudFront→origin leg is encrypted.)
- **Public IP** for internet egress (ECR, Docker, ACME/DNS, AWS APIs) — no NAT gateway.
- **Access** via SSM Session Manager (no SSH key, no inbound `:22`).
- **IAM role**: `AmazonSSMManagedInstanceCore`, ECR pull, read of the configured SSM
  parameters (+ `kms:Decrypt` for SecureStrings via the SSM service), plus the caller's
  `additional_iam_policy_json` for app permissions.
- **IMDS**: v2-only, hop limit 2 so Docker containers can assume the instance role.

The module makes the box *deploy-ready*; pushing the app (copy compose/Caddyfile, `docker
compose up`) is done by CI over SSM.

## Usage

```hcl
module "app_server" {
  source = "git::ssh://git@github.com/pjosols/wsht-terraform.git//modules/app_server?ref=vX.Y.Z"

  name      = "wsht-mail-api"
  vpc_id    = data.aws_vpc.default.id
  subnet_id = data.aws_subnet.public.id

  ecr_repository_arns         = [aws_ecr_repository.api.arn]
  readable_ssm_parameter_arns = [aws_ssm_parameter.caddy_cf_token.arn] # or the CLI-created ARN
  additional_iam_policy_json  = data.aws_iam_policy_document.app.json   # S3 Vectors, DynamoDB, Bedrock, S3
  tags                        = local.tags
}
```

Point an origin DNS record (e.g. `origin.example.com`, DNS-only) at `module.app_server.public_ip`,
and use `https://origin.example.com` as a CloudFront custom origin (`origin_type = "custom"`).

## Inputs / Outputs

See `variables.tf` and `outputs.tf`. Key outputs: `instance_id`, `public_ip`,
`security_group_id`, `iam_role_name`.

## Replacing the instance

`ami` defaults to the latest Amazon Linux 2023 arm64 image, read from AWS's SSM pointer. That
pointer moves whenever AWS publishes a new image, so the instance carries
`lifecycle { ignore_changes = [ami] }`: an apply for something unrelated can never destroy and
recreate a running box on its own.

Moving to a newer image is therefore explicit:

```
terraform apply -replace=module.<name>.aws_instance.this
```

Set `ami` if you want to choose the image rather than take whatever is current at that moment.
Leaving it null keeps the default. Because the instance is replaced, expect the usual
consequences — a fresh box that your deploy must re-seed, and anything on local disk gone.
