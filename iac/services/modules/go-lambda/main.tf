data "aws_ssm_parameter" "database_url" {
  name = "/${var.name}/postgresdb/host"
}

data "aws_secretsmanager_secret" "circulatedb_user_secret" {
  name = "/${var.name}/postgresdb/admin"
}

data "aws_secretsmanager_secret_version" "circulatedb_user_secret_version" {
  secret_id     = data.aws_secretsmanager_secret.circulatedb_user_secret.id
}

resource "aws_lambda_function" "go_function" {
  depends_on    = [
    aws_cloudwatch_log_group.log_group, 
    null_resource.gobuild
  ]
  filename      = "${var.src_path}/assets/${random_uuid.lambda_src_hash.result}.zip"
  function_name = var.lambda_name
  role          = aws_iam_role.lambda.arn
  runtime       = "go1.x"
  handler       = "main"
  timeout       = var.timeout

  environment {
    variables = merge(
        {
            DB_CLIENT = "${data.aws_ssm_parameter.database_url.value}"
            DB_USER = "${jsondecode(data.aws_secretsmanager_secret_version.circulatedb_user_secret_version.secret_string)["username"]}"
            DB_PASS = "${jsondecode(data.aws_secretsmanager_secret_version.circulatedb_user_secret_version.secret_string)["password"]}"
        }, 
        var.env_variables
    )
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 7
}
