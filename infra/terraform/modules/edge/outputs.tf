output "certificate_arn" {
  description = "Validated ACM certificate ARN for the HTTPS listener."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "web_acl_arn" {
  description = "WAFv2 web ACL protecting the ALB."
  value       = aws_wafv2_web_acl.this.arn
}

output "app_fqdn" {
  description = "Public host name of the application."
  value       = aws_route53_record.app.fqdn
}
