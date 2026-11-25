# Shared fake values for the mocked AWS provider. Nothing here talks to AWS.

mock_data "aws_availability_zones" {
  defaults = {
    names = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  }
}

mock_data "aws_caller_identity" {
  defaults = {
    account_id = "111122223333"
  }
}

mock_data "aws_partition" {
  defaults = {
    partition = "aws"
  }
}

mock_data "aws_region" {
  defaults = {
    region = "ap-south-1"
  }
}

mock_data "aws_iam_policy_document" {
  defaults = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

mock_data "aws_ssm_parameter" {
  defaults = {
    value = "ami-0abc1234def567890"
  }
}

mock_data "aws_route53_zone" {
  defaults = {
    zone_id = "Z0MOCKZONE123"
  }
}

mock_data "aws_elb_service_account" {
  defaults = {
    arn = "arn:aws:iam::718504428378:root"
  }
}

mock_resource "aws_kms_key" {
  defaults = {
    arn = "arn:aws:kms:ap-south-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  }
}

mock_resource "aws_db_instance" {
  defaults = {
    address = "tally-test.abc123.ap-south-1.rds.amazonaws.com"
    port    = 3306
    master_user_secret = [{
      secret_arn    = "arn:aws:secretsmanager:ap-south-1:111122223333:secret:rds!db-mock"
      kms_key_id    = "arn:aws:kms:ap-south-1:111122223333:key/00000000-0000-0000-0000-000000000000"
      secret_status = "active"
    }]
  }
}

mock_resource "aws_ecr_repository" {
  defaults = {
    arn            = "arn:aws:ecr:ap-south-1:111122223333:repository/tally-test/tallybook"
    repository_url = "111122223333.dkr.ecr.ap-south-1.amazonaws.com/tally-test/tallybook"
  }
}

mock_resource "aws_route53_record" {
  defaults = {
    fqdn = "tally.example.com"
  }
}

# The AWS provider validates ARN-typed arguments even when mocked, so every
# resource whose ARN feeds another resource gets a well-formed fake ARN.

mock_resource "aws_iam_role" {
  defaults = {
    arn = "arn:aws:iam::111122223333:role/mock-role"
  }
}

mock_resource "aws_iam_instance_profile" {
  defaults = {
    arn = "arn:aws:iam::111122223333:instance-profile/mock-profile"
  }
}

mock_resource "aws_cloudwatch_log_group" {
  defaults = {
    arn = "arn:aws:logs:ap-south-1:111122223333:log-group:mock"
  }
}

mock_resource "aws_lb" {
  defaults = {
    arn      = "arn:aws:elasticloadbalancing:ap-south-1:111122223333:loadbalancer/app/tally-test-alb/0123456789abcdef"
    dns_name = "tally-test-alb-123456.ap-south-1.elb.amazonaws.com"
    zone_id  = "ZP97RAFLXTNZK"
  }
}

mock_resource "aws_lb_target_group" {
  defaults = {
    arn = "arn:aws:elasticloadbalancing:ap-south-1:111122223333:targetgroup/tally-0123/0123456789abcdef"
  }
}

mock_resource "aws_s3_bucket" {
  defaults = {
    arn = "arn:aws:s3:::tally-test-alb-logs-mock"
  }
}

mock_resource "aws_wafv2_web_acl" {
  defaults = {
    arn = "arn:aws:wafv2:ap-south-1:111122223333:regional/webacl/tally-test-web-acl/0000"
  }
}

# Known during plan so the DNS-validation for_each can be expanded.
mock_resource "aws_acm_certificate" {
  override_during = plan
  defaults = {
    arn                 = "arn:aws:acm:ap-south-1:111122223333:certificate/mock"
    id                  = "arn:aws:acm:ap-south-1:111122223333:certificate/mock"
    key_algorithm       = "RSA_2048"
    not_after           = "2027-12-01T00:00:00Z"
    not_before          = "2026-12-01T00:00:00Z"
    region              = "ap-south-1"
    renewal_eligibility = "ELIGIBLE"
    status              = "ISSUED"
    type                = "AMAZON_ISSUED"
    domain_validation_options = [{
      domain_name           = "tally.example.com"
      resource_record_name  = "_abc.tally.example.com."
      resource_record_type  = "CNAME"
      resource_record_value = "_xyz.acm-validations.aws."
    }]
  }
}

mock_resource "aws_acm_certificate_validation" {
  defaults = {
    certificate_arn = "arn:aws:acm:ap-south-1:111122223333:certificate/mock"
  }
}

mock_resource "aws_launch_template" {
  defaults = {
    id             = "lt-0123456789abcdef0"
    latest_version = 1
  }
}
