output "app_url" {
  description = "Public HTTPS URL of the application."
  value       = "https://${module.edge.app_fqdn}"
}

output "alb_dns_name" {
  description = "ALB DNS name (the Route 53 alias points here)."
  value       = module.web.alb_dns_name
}

output "ecr_repository_url" {
  description = "Push the application image here before scaling the web tier."
  value       = aws_ecr_repository.app.repository_url
}

output "db_endpoint" {
  description = "Private RDS endpoint (reachable only from the web tier)."
  value       = module.database.endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager ARN of the RDS-managed master credentials."
  value       = module.database.master_secret_arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.network.vpc_id
}

output "asg_name" {
  description = "Web tier Auto Scaling group."
  value       = module.web.asg_name
}
