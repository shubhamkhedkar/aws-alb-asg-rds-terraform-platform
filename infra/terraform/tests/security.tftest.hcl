mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  name   = "tally-test"
  vpc_id = "vpc-0mock"
}

run "tiers_reference_each_other_not_cidrs" {
  command = apply

  module {
    source = "./modules/security"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.web_from_alb.referenced_security_group_id == aws_security_group.alb.id
    error_message = "Web tier must only accept traffic from the ALB security group."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.db_from_web.referenced_security_group_id == aws_security_group.web.id
    error_message = "Database must only accept traffic from the web security group."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.db_from_web.from_port == 3306 && aws_vpc_security_group_ingress_rule.db_from_web.to_port == 3306
    error_message = "Database ingress must be limited to the MySQL port."
  }

  assert {
    condition     = aws_vpc_security_group_egress_rule.alb_to_web.from_port == 8080 && aws_vpc_security_group_egress_rule.alb_to_web.referenced_security_group_id == aws_security_group.web.id
    error_message = "ALB egress must be limited to the web tier on the app port."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.web_from_alb.cidr_ipv4 == null
    error_message = "Web tier ingress must not be CIDR based."
  }
}

run "custom_client_cidrs" {
  command = apply

  module {
    source = "./modules/security"
  }

  variables {
    alb_ingress_cidrs = ["203.0.113.0/24", "198.51.100.0/24"]
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.alb_https) == 2
    error_message = "Each client CIDR should get its own HTTPS rule."
  }
}
