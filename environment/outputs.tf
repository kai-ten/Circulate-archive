# VPC Environment output
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

output "integration_security_group_id" {
  value = module.integration_security_group.security_group_id
}

output "okta_secret_name" {
  value = aws_secretsmanager_secret.circulate_okta_api.name
}

output "database_secret_name" {
  value = aws_secretsmanager_secret.circulate_postgresdb.name
}


# Data Lake Output
output "data_lake_s3" {
  value = module.circulate_data_lake
}

output "data_lake_s3_sfn_tmp" {
  value = module.circulate_data_lake_sfn_tmp
}

output "data_lake_s3_iac" {
  value = module.circulate_iac
}

output "data_lake_efs" {
  value = module.efs
}

output "dbt_ecs_cluster" {
  value = aws_ecs_cluster.circulate_ecs_cluster
}
