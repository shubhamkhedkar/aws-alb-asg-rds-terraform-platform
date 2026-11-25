mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  name                  = "tally-test"
  vpc_id                = "vpc-0mock"
  public_subnet_ids     = ["subnet-pub-a", "subnet-pub-b"]
  app_subnet_ids        = ["subnet-app-a", "subnet-app-b"]
  alb_security_group_id = "sg-0alb"
  web_security_group_id = "sg-0web"
  certificate_arn       = "arn:aws:acm:ap-south-1:111122223333:certificate/mock"
  kms_key_arn           = "arn:aws:kms:ap-south-1:111122223333:key/test"
  app_image             = "111122223333.dkr.ecr.ap-south-1.amazonaws.com/tally-test/tallybook:1.0.0"
  ecr_repository_arn    = "arn:aws:ecr:ap-south-1:111122223333:repository/tally-test/tallybook"
  db_host               = "tally-test.abc123.ap-south-1.rds.amazonaws.com"
  db_name               = "tallybook"
  db_secret_arn         = "arn:aws:secretsmanager:ap-south-1:111122223333:secret:rds!db-mock"
}

run "hardened_launch_template" {
  command = apply

  module {
    source = "./modules/web"
  }

  assert {
    condition     = aws_launch_template.web.metadata_options[0].http_tokens == "required" && aws_launch_template.web.metadata_options[0].http_put_response_hop_limit == 1
    error_message = "Instances must enforce IMDSv2 with a hop limit of 1."
  }

  assert {
    condition     = aws_launch_template.web.block_device_mappings[0].ebs[0].encrypted == "true"
    error_message = "Root volumes must be encrypted."
  }

  assert {
    condition     = aws_launch_template.web.image_id == "ami-0abc1234def567890"
    error_message = "AMI must come from the SSM public parameter."
  }

  assert {
    condition     = length(aws_launch_template.web.key_name) == 0 || aws_launch_template.web.key_name == null
    error_message = "No SSH key pair: access is via SSM Session Manager."
  }

  assert {
    condition     = strcontains(base64decode(aws_launch_template.web.user_data), var.db_secret_arn) && strcontains(base64decode(aws_launch_template.web.user_data), "jq -r .password")
    error_message = "User data must read the password from Secrets Manager at boot, not embed it."
  }
}

run "asg_and_listeners" {
  command = apply

  module {
    source = "./modules/web"
  }

  assert {
    condition     = aws_autoscaling_group.web.health_check_type == "ELB" && aws_autoscaling_group.web.min_size == 2 && aws_autoscaling_group.web.max_size == 6
    error_message = "ASG should use ELB health checks and span 2-6 instances."
  }

  assert {
    condition     = aws_lb_listener.https.ssl_policy == "ELBSecurityPolicy-TLS13-1-2-2021-06"
    error_message = "HTTPS listener must use the TLS 1.2/1.3 policy."
  }

  assert {
    condition     = aws_lb_listener.http_redirect.default_action[0].type == "redirect" && aws_lb_listener.http_redirect.default_action[0].redirect[0].status_code == "HTTP_301"
    error_message = "Port 80 must only redirect to HTTPS."
  }

  assert {
    condition     = aws_lb.this.drop_invalid_header_fields && aws_lb.this.access_logs[0].enabled
    error_message = "ALB must drop invalid headers and ship access logs."
  }

  assert {
    condition     = aws_lb_target_group.app.health_check[0].path == "/healthz"
    error_message = "Target group should probe the liveness endpoint."
  }
}

run "rejects_long_name" {
  command = plan

  module {
    source = "./modules/web"
  }

  variables {
    name = "this-name-is-way-too-long-for-an-alb"
  }

  expect_failures = [var.name]
}
