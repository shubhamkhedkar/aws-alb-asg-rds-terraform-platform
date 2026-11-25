variable "name" {
  description = "Name prefix for edge resources."
  type        = string
}

variable "domain_name" {
  description = "Fully qualified host name served by the ALB, e.g. tally.example.com."
  type        = string
}

variable "hosted_zone_name" {
  description = "Existing public Route 53 hosted zone that owns domain_name, e.g. example.com."
  type        = string
}

variable "alb_arn" {
  description = "ALB to protect with WAF (set after the web module exists)."
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name for the alias record."
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID for the alias record."
  type        = string
}

variable "rate_limit_per_5min" {
  description = "Requests per client IP per 5 minutes before WAF blocks."
  type        = number
  default     = 2000
}

variable "kms_key_arn" {
  description = "KMS key for the WAF log group."
  type        = string
}

variable "log_retention_days" {
  description = "Retention for WAF logs."
  type        = number
  default     = 365
}

variable "tags" {
  description = "Extra tags for every resource."
  type        = map(string)
  default     = {}
}
