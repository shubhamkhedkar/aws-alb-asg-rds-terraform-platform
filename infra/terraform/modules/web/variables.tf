variable "name" {
  description = "Name prefix for web tier resources (keep it short: ALB/TG names max 32 chars)."
  type        = string

  validation {
    condition     = length(var.name) <= 20
    error_message = "name must be 20 characters or fewer so derived ALB/target group names stay within AWS limits."
  }
}

variable "vpc_id" {
  description = "VPC for the target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB."
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "Private subnets for the Auto Scaling group."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group for the ALB."
  type        = string
}

variable "web_security_group_id" {
  description = "Security group for web instances."
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate for the HTTPS listener."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key for EBS volumes and decrypting the DB secret."
  type        = string
}

variable "app_port" {
  description = "Port the container is published on."
  type        = number
  default     = 8080
}

variable "app_image" {
  description = "Container image (ECR URI with tag or digest) the instances run."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository the instances may pull from."
  type        = string
}

variable "ami_ssm_parameter" {
  description = "Public SSM parameter that resolves to the latest Amazon Linux 2023 AMI."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

variable "instance_type" {
  description = "EC2 instance type (Graviton by default to match the arm64 AMI)."
  type        = string
  default     = "t4g.small"
}

variable "min_size" {
  description = "Minimum instances in the ASG."
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired instances in the ASG."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum instances in the ASG."
  type        = number
  default     = 6

  validation {
    condition     = var.max_size >= 1
    error_message = "max_size must be at least 1."
  }
}

variable "cpu_target_percent" {
  description = "Average CPU the target tracking policy aims for."
  type        = number
  default     = 50
}

variable "db_host" {
  description = "RDS endpoint the application connects to."
  type        = string
}

variable "db_port" {
  description = "RDS port."
  type        = number
  default     = 3306
}

variable "db_name" {
  description = "Schema the application uses."
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager secret holding the DB credentials (RDS-managed)."
  type        = string
}

variable "alb_deletion_protection" {
  description = "Block accidental deletion of the ALB."
  type        = bool
  default     = true
}

variable "access_log_retention_days" {
  description = "Days to keep ALB access logs in S3."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Extra tags for every resource."
  type        = map(string)
  default     = {}
}
