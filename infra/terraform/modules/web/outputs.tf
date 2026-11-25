output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (for Route 53 alias records)."
  value       = aws_lb.this.zone_id
}

output "asg_name" {
  description = "Name of the web tier Auto Scaling group."
  value       = aws_autoscaling_group.web.name
}

output "target_group_arn" {
  description = "Target group behind the HTTPS listener."
  value       = aws_lb_target_group.app.arn
}

output "access_log_bucket" {
  description = "S3 bucket receiving ALB access logs."
  value       = aws_s3_bucket.alb_logs.id
}
