data "terraform_remote_state" "data_lake_output" {
  backend = "s3"
  config = {
    bucket = "${var.name}-${var.env}-terraform-state-backend"
    key    = "data-lake/terraform.tfstate"
    region = "us-east-2"
  }
}

data "aws_caller_identity" "current" {}

module "s3_writer" {
  source          = "../../../modules/go-lambda"
  name            = "${var.name}-${var.env}-${var.service}"
  lambda_name     = "${var.name}-${var.env}-${var.service}"
  src_path        = "../lib"
  iam_policy_json = data.aws_iam_policy_document.lambda_policy.json
  timeout = 5
  env_variables = {
    SOURCE_BUCKET = "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_sfn_tmp.s3_bucket_id}"
    TARGET_BUCKET = "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3.s3_bucket_id}"
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_sfn_tmp.s3_bucket_arn}",
      "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3.s3_bucket_arn}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:PutObjectAcl",
    ]
    resources = [
      "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_sfn_tmp.s3_bucket_arn}/*",
      "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3.s3_bucket_arn}/*"
    ]
  }
}
