variable "name" {
  description = "Identifier prefix for the RDS resources."
  type        = string
}

variable "subnet_ids" {
  description = "Isolated database subnets (at least two AZs)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "RDS needs subnets in at least two availability zones."
  }
}

variable "security_group_id" {
  description = "Security group that only admits the web tier."
  type        = string
}

variable "kms_key_arn" {
  description = "Customer managed KMS key for storage, Performance Insights, logs and the master secret."
  type        = string
}

variable "engine_version" {
  description = "MySQL engine version."
  type        = string
  default     = "8.4"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.medium"
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Storage autoscaling ceiling in GiB."
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Initial schema created on the instance."
  type        = string
  default     = "tallybook"
}

variable "master_username" {
  description = "Master user name. The password is generated and stored by RDS in Secrets Manager."
  type        = string
  default     = "tally_admin"
}

variable "multi_az" {
  description = "Run a synchronous standby in a second AZ."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Automated backup retention."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 1 and 35."
  }
}

variable "deletion_protection" {
  description = "Block accidental deletion of the instance."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention for exported RDS logs."
  type        = number
  default     = 365
}

variable "tags" {
  description = "Extra tags for every resource."
  type        = map(string)
  default     = {}
}
