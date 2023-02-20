data "aws_secretsmanager_secret" "postgres_secret" {
  name = "${var.database_secret_name}"
}

data "aws_caller_identity" "current" {}

module "json_writer" {

  count = (var.enabled && var.endpoint == "postgres") == true ? 1 : 0

  source          = "../../../modules/go-lambda"
  name            = "${var.name}-${var.env}-${var.service}"
  lambda_name     = "${var.name}-${var.env}-${var.service}"
  src_path        = "${var.src_path}"
  iam_policy_json = data.aws_iam_policy_document.lambda_policy.json
  timeout = 60
  vpc_config = {
    security_group_ids = [var.integration_security_group_id]
    subnet_ids = var.vpc_private_subnets
  }
  env_variables = {
    DATABASE_SECRET = "${var.database_secret_name}"
    AWS_S3_SFN_TMP_BUCKET = "${var.data_lake_sfn_bucket.s3_bucket_id}"
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${var.data_lake_sfn_bucket.s3_bucket_arn}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${var.data_lake_sfn_bucket.s3_bucket_arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets"
    ]
    resources = [
      "${data.aws_secretsmanager_secret.postgres_secret.arn}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface"
    ]
    resources = [
      "*"
    ]
  }
}
