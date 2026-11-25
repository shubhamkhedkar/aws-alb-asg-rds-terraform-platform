variable "name" {
  description = "Name prefix for the security groups."
  type        = string
}

variable "vpc_id" {
  description = "VPC that owns the security groups."
  type        = string
}

variable "app_port" {
  description = "Port the application listens on inside each instance."
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database listener port."
  type        = number
  default     = 3306
}

variable "alb_ingress_cidrs" {
  description = "Client CIDRs allowed to reach the load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Extra tags for every resource."
  type        = map(string)
  default     = {}
}
