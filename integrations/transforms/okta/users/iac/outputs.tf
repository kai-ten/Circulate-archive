output "ecs_task_def_arn" {
  value = module.dbt_profiles_generator.ecs_task_def_arn
}

output "security_group_id" {
  value = module.dbt_profiles_generator.security_group_id
}

output "task_exec_role_arn" {
    value = module.dbt_profiles_generator.task_exec_role_arn
}

output "task_role_arn" {
    value = module.dbt_profiles_generator.task_role_arn
}
