output "endpoint" {
  description = "Writer endpoint (host only)."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Database port."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Initial schema name."
  value       = aws_db_instance.this.db_name
}

output "master_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret holding the master credentials."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "instance_arn" {
  description = "ARN of the DB instance."
  value       = aws_db_instance.this.arn
}
