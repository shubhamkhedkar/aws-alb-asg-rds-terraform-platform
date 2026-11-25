output "state_bucket" {
  description = "Bucket name to put in backend.hcl."
  value       = aws_s3_bucket.state.id
}

output "state_kms_alias" {
  description = "KMS alias to put in backend.hcl."
  value       = aws_kms_alias.state.name
}
