data "aws_availability_zones" "available" {
  #checkov:skip=CKV_AWS_394:Result is sliced to var.az_count, so new AZs never change the layout
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}
