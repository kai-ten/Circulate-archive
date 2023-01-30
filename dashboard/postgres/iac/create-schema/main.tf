data "terraform_remote_state" "vpc_output" {
  backend = "s3"
  config = {
    bucket = "${var.name}-${var.env}-terraform-state-backend"
    key    = "vpc/terraform.tfstate"
    region = "us-east-2"
  }
}

data "aws_secretsmanager_secret" "database_secret" {
  name = data.terraform_remote_state.vpc_output.outputs.database_secret_name
}

data "aws_iam_policy" "AWSLambdaVPCAccessExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "create_database_policy" {
  source_policy_documents = [data.aws_iam_policy.AWSLambdaVPCAccessExecutionRole.policy]

  statement {
    actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecrets"
      ]
    resources = [
      "${data.aws_secretsmanager_secret.database_secret.arn}"
    ]
  }
}

module "circulate_create_schema" {
  source          = "../../../../integrations/modules/go-lambda"
  name            = "${var.name}-${var.env}"
  lambda_name     = "${var.name}-${var.env}-${var.service}"
  src_path        = "../../lib/create-schema"
  iam_policy_json = data.aws_iam_policy_document.create_database_policy.json
  timeout = 30
  vpc_config = {
    security_group_ids = [data.terraform_remote_state.vpc_output.outputs.integration_security_group_id]
    subnet_ids = data.terraform_remote_state.vpc_output.outputs.vpc_private_subnets
  }
  env_variables = {
    "DATABASE_SECRET" = "${data.terraform_remote_state.vpc_output.outputs.database_secret_name}"
  }
}

resource "null_resource" "db_setup" {
  triggers = {
    resource = module.circulate_create_schema.lambda_function.version # build triggers after resource exists
  }
  provisioner "local-exec" {
    command = <<-EOF
			aws lambda invoke --function-name "$FUNCTION_NAME" /dev/stdout 2>/dev/null
			EOF
    environment = {
      FUNCTION_NAME     = module.circulate_create_schema.lambda_function.function_name
    }
    interpreter = ["bash", "-c"]
  }
  depends_on = [
    module.circulate_create_schema
  ]
}