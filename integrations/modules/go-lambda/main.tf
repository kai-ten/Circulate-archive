locals {
  environment_map = var.env_variables[*]
}

resource "aws_lambda_function" "go_function" {
  depends_on    = [
    aws_cloudwatch_log_group.log_group,
    null_resource.gobuild,
  ]
  
  filename      = "${var.src_path}/assets/${random_uuid.lambda_src_hash.result}.zip"
  function_name = var.lambda_name
  role          = aws_iam_role.lambda.arn
  runtime       = "go1.x"
  handler       = "assets/main"
  timeout       = var.timeout
  publish = true

  dynamic "environment" {
    for_each = local.environment_map
    content {
      variables = environment.value
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config == null ? [] : [0]
    content {
      security_group_ids = var.vpc_config.security_group_ids
      subnet_ids         = var.vpc_config.subnet_ids
    }
  }

  dynamic "file_system_config" {
    for_each = var.efs_config == null ? [] : [0]
    content {
      arn = var.efs_config.arn
      local_mount_path = var.efs_config.mount_path
    }
  }

}

resource "aws_cloudwatch_log_group" "log_group" {
  name_prefix = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 7
}
