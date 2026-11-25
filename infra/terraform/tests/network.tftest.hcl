mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  name               = "tally-test"
  vpc_cidr           = "10.40.0.0/16"
  availability_zones = ["ap-south-1a", "ap-south-1b"]
  kms_key_arn        = "arn:aws:kms:ap-south-1:111122223333:key/test"
}

run "three_tiers_across_two_azs" {
  command = apply

  module {
    source = "./modules/network"
  }

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.app) == 2 && length(aws_subnet.database) == 2
    error_message = "Expected two subnets per tier."
  }

  assert {
    condition     = output.subnet_cidrs.app == ["10.40.10.0/24", "10.40.11.0/24"] && output.subnet_cidrs.database == ["10.40.20.0/24", "10.40.21.0/24"]
    error_message = "Subnet CIDR plan changed unexpectedly."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "Public subnets must not auto-assign public IPs (only the ALB and NAT live there)."
  }

  assert {
    condition     = output.nat_gateway_count == 2
    error_message = "Production layout should have one NAT gateway per AZ."
  }

  assert {
    condition     = aws_flow_log.this.traffic_type == "ALL"
    error_message = "VPC flow logs must capture all traffic."
  }
}

run "shared_nat_for_cheaper_envs" {
  command = apply

  module {
    source = "./modules/network"
  }

  variables {
    single_nat_gateway = true
  }

  assert {
    condition     = output.nat_gateway_count == 1
    error_message = "single_nat_gateway should create exactly one NAT gateway."
  }

  assert {
    condition     = aws_route.app_nat[0].nat_gateway_id == aws_route.app_nat[1].nat_gateway_id
    error_message = "Both app route tables should share the single NAT gateway."
  }
}

run "rejects_single_az" {
  command = plan

  module {
    source = "./modules/network"
  }

  variables {
    availability_zones = ["ap-south-1a"]
  }

  expect_failures = [var.availability_zones]
}

run "rejects_tiny_vpc" {
  command = plan

  module {
    source = "./modules/network"
  }

  variables {
    vpc_cidr = "10.40.0.0/24"
  }

  expect_failures = [var.vpc_cidr]
}
