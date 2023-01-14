output "database_url" {
  value = module.db.db_instance_endpoint
}

output "database_secret_name" {
  value = aws_secretsmanager_secret.circulate_db.name
}
