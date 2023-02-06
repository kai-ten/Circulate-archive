output "lambda_function" {
  value = module.dbt_profiles_generator.lambda_function
}

output "ecs_task_def_arn" {
  value = aws_ecs_task_definition.task.arn
}

output "security_group_id" {
  value = module.dbt_lambda_security_group.security_group_id
}

output "task_exec_role_arn" {
  value = aws_iam_role.circulate_ecs_task_exec_role.arn
}

output "task_role_arn" {
  value = aws_iam_role.circulate_ecs_task_role.arn
}
 