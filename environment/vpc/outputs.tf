output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}

output "vpc_private_subnets" {
  value = module.vpc.private_subnets
}

output "vpc_private_subnet_cidrs" {
  value = module.vpc.private_subnets_cidr_blocks
}

output "vpc_database_subnet_group" {
  value = module.vpc.database_subnet_group
}

output "integration_security_group_id" {
  value = module.integration_security_group.security_group_id
}

output "okta_secret_name" {
  value = aws_secretsmanager_secret.circulate_okta_api.name
}

output "database_secret_name" {
  value = aws_secretsmanager_secret.circulate_postgresdb.name
}
