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

data "aws_secretsmanager_secret" "okta_secret" {
  name = "${data.terraform_remote_state.vpc_output.outputs.okta_secret_name}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "okta_users" {
  source          = "../../../../modules/go-lambda"
  name            = "${var.name}-${var.env}-${var.service}-${var.endpoint}"
  lambda_name     = "${var.name}-${var.env}-${var.service}-${var.endpoint}"
  src_path        = "../../lib/users"
  iam_policy_json = data.aws_iam_policy_document.lambda_policy.json
  env_variables = {
    AWS_S3_SFN_TMP_BUCKET = "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_sfn_tmp.s3_bucket_id}"
    AWS_S3_REGION = "${data.aws_region.current.name}"
    API_SECRETS   = "${data.terraform_remote_state.vpc_output.outputs.okta_secret_name}"
    CIRCULATE_SERVICE = "${var.service}"
    CIRCULATE_ENDPOINT = "${var.endpoint}"
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_sfn_tmp.s3_bucket_arn}"
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
      "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_sfn_tmp.s3_bucket_arn}/*"
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets"
    ]
    resources = [
      "${data.aws_secretsmanager_secret.okta_secret.arn}"
    ]
  }
}
