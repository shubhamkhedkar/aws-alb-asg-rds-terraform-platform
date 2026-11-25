output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnets (ALB and NAT gateways only)."
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Private subnets for the web/app Auto Scaling group."
  value       = aws_subnet.app[*].id
}

output "database_subnet_ids" {
  description = "Isolated subnets for RDS (no internet route)."
  value       = aws_subnet.database[*].id
}

output "nat_gateway_count" {
  description = "Number of NAT gateways created."
  value       = length(aws_nat_gateway.this)
}

output "subnet_cidrs" {
  description = "CIDR blocks per tier, useful for reviews and tests."
  value = {
    public   = local.public_cidrs
    app      = local.app_cidrs
    database = local.database_cidrs
  }
}
