variable "name" {
  description = "Name prefix applied to every network resource."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC. A /16 leaves room for the three subnet tiers."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 20
    error_message = "vpc_cidr must be a valid IPv4 CIDR no smaller than /20."
  }
}

variable "availability_zones" {
  description = "Availability zones to spread the subnets across (exactly two or three)."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 3
    error_message = "Provide two or three availability zones for high availability."
  }
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway instead of one per AZ (cheaper, but a single AZ failure removes egress)."
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Retention for VPC flow logs in CloudWatch Logs."
  type        = number
  default     = 365
}

variable "kms_key_arn" {
  description = "KMS key used to encrypt the flow log group."
  type        = string
}

variable "tags" {
  description = "Extra tags for every resource."
  type        = map(string)
  default     = {}
}
