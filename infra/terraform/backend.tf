# Remote state in S3 with native lock files (Terraform >= 1.10, no DynamoDB table needed).
# Values are supplied at init time so the same code serves every environment:
#   terraform init -backend-config=backend.hcl
# See backend.hcl.example and infra/bootstrap for creating the bucket.
terraform {
  backend "s3" {}
}
