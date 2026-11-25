output "alb_security_group_id" {
  description = "Security group attached to the ALB."
  value       = aws_security_group.alb.id
}

output "web_security_group_id" {
  description = "Security group attached to web tier instances."
  value       = aws_security_group.web.id
}

output "db_security_group_id" {
  description = "Security group attached to the RDS instance."
  value       = aws_security_group.db.id
}
