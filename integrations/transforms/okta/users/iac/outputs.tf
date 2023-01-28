output "ecr_repo" {
  value = aws_ecr_repository.dbt_postgres_ecr_repo.name
}
