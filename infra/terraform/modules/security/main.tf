# Least-privilege chain: internet -> ALB (443/80) -> web (app_port) -> RDS (db_port).
# Every hop references the previous security group instead of a CIDR range.

resource "aws_security_group" "alb" {
  #checkov:skip=CKV2_AWS_5:Attached by the web and database modules
  name_prefix = "${var.name}-alb-"
  description = "Public entry point: HTTPS (and HTTP redirect) from clients"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-alb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "web" {
  #checkov:skip=CKV2_AWS_5:Attached by the web and database modules
  name_prefix = "${var.name}-web-"
  description = "Web tier instances: app traffic from the ALB only"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-web" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "db" {
  #checkov:skip=CKV2_AWS_5:Attached by the web and database modules
  name_prefix = "${var.name}-db-"
  description = "Database tier: MySQL from the web tier only"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-db" })

  lifecycle {
    create_before_destroy = true
  }
}

# --- ALB ---------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.alb_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from clients"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_redirect" {
  #checkov:skip=CKV_AWS_260:Port 80 only serves a 301 redirect to HTTPS (see web module listener)
  for_each = toset(var.alb_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from clients, answered only with a 301 to HTTPS"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward to web tier on the app port"
  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# --- Web tier ----------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  security_group_id            = aws_security_group.web.id
  description                  = "App port from the ALB"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "web_to_db" {
  security_group_id            = aws_security_group.web.id
  description                  = "MySQL to the database tier"
  referenced_security_group_id = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
}

# HTTPS-only egress through NAT; VPC interface endpoints are a documented follow-up.
# trivy:ignore:AWS-0104
resource "aws_vpc_security_group_egress_rule" "web_https_out" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS via NAT for SSM, ECR, Secrets Manager and OS packages"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# --- Database tier -----------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "db_from_web" {
  security_group_id            = aws_security_group.db.id
  description                  = "MySQL from the web tier"
  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
}
# No egress rules on the DB group: RDS never initiates outbound connections.
