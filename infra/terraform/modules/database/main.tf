locals {
  major_version = join(".", slice(split(".", var.engine_version), 0, 2))
  log_exports   = ["error", "slowquery", "iam-db-auth-error"]
}

resource "aws_db_subnet_group" "this" {
  name_prefix = "${var.name}-"
  description = "Isolated subnets for ${var.name}"
  subnet_ids  = var.subnet_ids
  tags        = var.tags
}

resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.name}-mysql-"
  family      = "mysql${local.major_version}"
  description = "TLS-only connections and slow query logging"

  parameter {
    name  = "require_secure_transport"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Pre-create the log groups so they are KMS-encrypted and have a retention policy.
resource "aws_cloudwatch_log_group" "rds" {
  for_each = toset(local.log_exports)

  name              = "/aws/rds/instance/${var.name}/${each.value}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = var.tags
}

data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name_prefix        = "${var.name}-rds-mon-"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.master_username

  # RDS generates and rotates the master password in Secrets Manager; it never
  # appears in Terraform variables, state or plan output.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false
  multi_az               = var.multi_az
  port                   = 3306

  iam_database_authentication_enabled = true

  backup_retention_period   = var.backup_retention_days
  backup_window             = "20:30-21:30"
  maintenance_window        = "sun:22:00-sun:23:00"
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name}-final"

  auto_minor_version_upgrade      = true
  enabled_cloudwatch_logs_exports = local.log_exports

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.kms_key_arn
  performance_insights_retention_period = 7

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.monitoring.arn

  tags = var.tags

  depends_on = [aws_cloudwatch_log_group.rds]
}
