data "terraform_remote_state" "vpc_output" {
  backend = "s3"
  config = {
    bucket = "${var.name}-${var.env}-terraform-state-backend"
    key    = "vpc/terraform.tfstate"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "data_lake_output" {
  backend = "s3"
  config = {
    bucket = "${var.name}-${var.env}-terraform-state-backend"
    key    = "data-lake/terraform.tfstate"
    region = "us-east-2"
  }
}

data "aws_secretsmanager_secret" "postgres_secret" {
  name = "${data.terraform_remote_state.vpc_output.outputs.database_secret_name}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "json_writer" {
  source          = "../../../modules/go-lambda"
  name            = "${var.name}-${var.env}-${var.service}"
  lambda_name     = "${var.name}-${var.env}-${var.service}"
  src_path        = "../lib"
  iam_policy_json = data.aws_iam_policy_document.lambda_policy.json
  env_variables = {
    DATABASE_SECRET = "${data.terraform_remote_state.vpc_output.outputs.database_secret_name}"
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3.s3_bucket_arn}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3.s3_bucket_arn}/*"
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets"
    ]
    resources = [
      "${data.aws_secretsmanager_secret.postgres_secret.arn}"
    ]
  }
}
