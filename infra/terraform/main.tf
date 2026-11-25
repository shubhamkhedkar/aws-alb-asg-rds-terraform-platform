locals {
  name = "tally-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  asg_service_role_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"

  app_port = 8080
}

module "network" {
  source = "./modules/network"

  name                    = local.name
  vpc_cidr                = var.vpc_cidr
  availability_zones      = local.azs
  single_nat_gateway      = var.single_nat_gateway
  kms_key_arn             = aws_kms_key.main.arn
  flow_log_retention_days = var.log_retention_days
}

module "security" {
  source = "./modules/security"

  name     = local.name
  vpc_id   = module.network.vpc_id
  app_port = local.app_port
  db_port  = 3306
}

module "database" {
  source = "./modules/database"

  name                = local.name
  subnet_ids          = module.network.database_subnet_ids
  security_group_id   = module.security.db_security_group_id
  kms_key_arn         = aws_kms_key.main.arn
  instance_class      = var.db_instance_class
  multi_az            = var.db_multi_az
  deletion_protection = var.deletion_protection
  log_retention_days  = var.log_retention_days
}

resource "aws_ecr_repository" "app" {
  name                 = "${local.name}/tallybook"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.main.arn
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the 20 most recent images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = { type = "expire" }
    }]
  })
}

module "web" {
  source = "./modules/web"

  name                    = local.name
  vpc_id                  = module.network.vpc_id
  public_subnet_ids       = module.network.public_subnet_ids
  app_subnet_ids          = module.network.app_subnet_ids
  alb_security_group_id   = module.security.alb_security_group_id
  web_security_group_id   = module.security.web_security_group_id
  certificate_arn         = module.edge.certificate_arn
  kms_key_arn             = aws_kms_key.main.arn
  app_port                = local.app_port
  app_image               = "${aws_ecr_repository.app.repository_url}:${var.app_image_tag}"
  ecr_repository_arn      = aws_ecr_repository.app.arn
  instance_type           = var.instance_type
  min_size                = var.asg_min_size
  desired_capacity        = var.asg_desired_capacity
  max_size                = var.asg_max_size
  db_host                 = module.database.endpoint
  db_port                 = module.database.port
  db_name                 = module.database.database_name
  db_secret_arn           = module.database.master_secret_arn
  alb_deletion_protection = var.deletion_protection
}

module "edge" {
  source = "./modules/edge"

  name               = local.name
  domain_name        = var.domain_name
  hosted_zone_name   = var.hosted_zone_name
  alb_arn            = module.web.alb_arn
  alb_dns_name       = module.web.alb_dns_name
  alb_zone_id        = module.web.alb_zone_id
  kms_key_arn        = aws_kms_key.main.arn
  log_retention_days = var.log_retention_days
}
