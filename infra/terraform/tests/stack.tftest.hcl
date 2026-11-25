mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  domain_name      = "tally.example.com"
  hosted_zone_name = "example.com"
}

run "full_stack_wires_together" {
  command = apply

  assert {
    condition     = output.app_url == "https://tally.example.com"
    error_message = "app_url should be the HTTPS host name."
  }

  assert {
    condition     = aws_kms_key.main.enable_key_rotation
    error_message = "The stack KMS key must rotate."
  }

  assert {
    condition     = aws_ecr_repository.app.image_tag_mutability == "IMMUTABLE" && aws_ecr_repository.app.image_scanning_configuration[0].scan_on_push
    error_message = "ECR must use immutable tags and scan on push."
  }

  assert {
    condition     = jsonencode(local.azs) == jsonencode(["ap-south-1a", "ap-south-1b"])
    error_message = "Default layout should use the first two AZs."
  }

  assert {
    condition     = output.db_secret_arn == "arn:aws:secretsmanager:ap-south-1:111122223333:secret:rds!db-mock"
    error_message = "Root should surface the managed DB secret ARN."
  }
}

run "three_az_dev_layout" {
  command = apply

  variables {
    environment        = "dev"
    az_count           = 3
    single_nat_gateway = true
  }

  assert {
    condition     = length(local.azs) == 3
    error_message = "az_count = 3 should spread across three AZs."
  }
}

run "rejects_bad_environment" {
  command = plan

  variables {
    environment = "Production_Env"
  }

  expect_failures = [var.environment]
}

run "rejects_four_azs" {
  command = plan

  variables {
    az_count = 4
  }

  expect_failures = [var.az_count]
}
