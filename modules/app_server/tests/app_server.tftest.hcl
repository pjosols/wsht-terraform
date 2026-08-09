# The three AWS-backed data sources are what kept this module out of CI: a real
# plan needs an SSM lookup, the CloudFront prefix list, and the current region.
# mock_data supplies all three, so the module plans offline like every other one.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }
  mock_data "aws_ssm_parameter" {
    defaults = { value = "ami-00000000000000001" }
  }
  mock_data "aws_ec2_managed_prefix_list" {
    defaults = { id = "pl-00000000000000001" }
  }
  # aws_iam_policy_document is provider-computed, so the mock hands back a generated
  # string for .json and aws_iam_role rejects it as "not a JSON object". A valid empty
  # policy keeps the plan moving. The cost: policy *contents* cannot be asserted here.
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}

variables {
  name      = "test-origin"
  vpc_id    = "vpc-00000000000000001"
  subnet_id = "subnet-00000000000000001"
}

run "plan_succeeds_with_required_vars" {
  command = plan
}

run "ami_defaults_to_ssm_latest" {
  command = plan

  assert {
    condition     = aws_instance.this.ami == "ami-00000000000000001"
    error_message = "ami must fall back to the AL2023 SSM parameter when var.ami is null"
  }
}

run "origin_reachable_only_from_cloudfront" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.https_from_cloudfront.prefix_list_id == "pl-00000000000000001"
    error_message = "ingress must be scoped to the CloudFront prefix list, never a CIDR"
  }

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.https_from_cloudfront.from_port == 443 &&
      aws_vpc_security_group_ingress_rule.https_from_cloudfront.to_port == 443
    )
    error_message = "only 443 may be open on the origin"
  }
}

run "instance_hardening_holds" {
  command = plan

  assert {
    condition     = aws_instance.this.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be required — IMDSv1 lets SSRF read instance credentials"
  }

  assert {
    condition     = aws_instance.this.root_block_device[0].encrypted
    error_message = "root volume must be encrypted"
  }

  assert {
    condition     = aws_instance.this.ebs_optimized
    error_message = "instance must be EBS optimized"
  }
}

run "detailed_monitoring_defaults_on_and_can_be_disabled" {
  command = plan

  assert {
    condition     = aws_instance.this.monitoring
    error_message = "detailed_monitoring must default to true"
  }
}

run "detailed_monitoring_opt_out" {
  command = plan

  variables {
    detailed_monitoring = false
  }

  assert {
    condition     = aws_instance.this.monitoring == false
    error_message = "detailed_monitoring = false must reach the instance (it is billed per instance)"
  }
}

run "elastic_ip_opt_out" {
  command = plan

  variables {
    assign_elastic_ip = false
  }

  assert {
    condition     = length(aws_eip.this) == 0
    error_message = "assign_elastic_ip = false must not allocate an Elastic IP"
  }
}

run "pinned_ami_wins" {
  command = plan

  variables {
    ami = "ami-00000000000000009"
  }

  assert {
    condition     = aws_instance.this.ami == "ami-00000000000000009"
    error_message = "an explicit var.ami must override the SSM lookup"
  }
}
