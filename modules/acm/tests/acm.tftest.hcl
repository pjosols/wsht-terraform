mock_provider "aws" {}

variables {
  domain_name = "example.com"
}

run "plan_succeeds_with_required_vars" {
  command = plan

  assert {
    condition     = aws_acm_certificate.this.domain_name == "example.com"
    error_message = "domain_name mismatch"
  }

  assert {
    condition     = aws_acm_certificate.this.validation_method == "DNS"
    error_message = "validation_method must be DNS"
  }
}

run "san_defaults_empty" {
  command = plan

  assert {
    condition     = length(aws_acm_certificate.this.subject_alternative_names) == 0
    error_message = "subject_alternative_names should default to empty"
  }
}

run "san_accepted" {
  command = plan

  variables {
    subject_alternative_names = ["www.example.com"]
  }

  assert {
    condition     = contains(tolist(aws_acm_certificate.this.subject_alternative_names), "www.example.com")
    error_message = "SAN not passed through"
  }
}

run "tags_applied" {
  command = plan

  variables {
    tags = { env = "test" }
  }

  assert {
    condition     = aws_acm_certificate.this.tags["env"] == "test"
    error_message = "tags not applied to certificate"
  }
}

run "outputs_not_null" {
  command = apply

  assert {
    condition     = aws_acm_certificate_validation.this.certificate_arn != null
    error_message = "certificate_arn output must not be null"
  }
}
