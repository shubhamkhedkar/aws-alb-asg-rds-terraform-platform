provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "tallybook"
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "shubhamkhedkar/aws-alb-asg-rds-terraform-platform"
    }
  }
}
