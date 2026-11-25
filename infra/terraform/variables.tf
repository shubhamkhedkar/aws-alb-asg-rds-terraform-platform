variable "region" {
  description = "AWS region for every resource."
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
  default     = "prod"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,9}$", var.environment))
    error_message = "environment must be 2-10 lowercase letters, digits or hyphens."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.40.0.0/16"
}

variable "az_count" {
  description = "How many availability zones to use (2 or 3)."
  type        = number
  default     = 2

  validation {
    condition     = contains([2, 3], var.az_count)
    error_message = "az_count must be 2 or 3."
  }
}

variable "single_nat_gateway" {
  description = "Share one NAT gateway across AZs to save cost in non-production environments."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Public host name for the app, e.g. tally.example.com."
  type        = string
}

variable "hosted_zone_name" {
  description = "Existing Route 53 public hosted zone, e.g. example.com."
  type        = string
}

variable "app_image_tag" {
  description = "Image tag (or immutable version) in the ECR repository to run on the web tier."
  type        = string
  default     = "1.0.0"
}

variable "instance_type" {
  description = "Web tier instance type."
  type        = string
  default     = "t4g.small"
}

variable "asg_min_size" {
  description = "Minimum web instances."
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired web instances."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum web instances."
  type        = number
  default     = 6
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.medium"
}

variable "db_multi_az" {
  description = "Run the database with a Multi-AZ standby."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection on the ALB and RDS instance."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for flow, RDS and WAF logs."
  type        = number
  default     = 365
}
