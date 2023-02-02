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
