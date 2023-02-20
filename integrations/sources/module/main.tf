data "aws_secretsmanager_secret" "api_secret_creds" {
  name = "/${var.name}-${var.env}/${var.service}/credentials"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "lambda" {

  count = var.enabled == true ? 1 : 0

  source          = "../../modules/go-lambda"
  name            = "${var.name}-${var.env}-${var.service}-${var.endpoint}"
  lambda_name     = "${var.name}-${var.env}-${var.service}-${var.endpoint}"
  src_path        = "${var.src_path}"
  iam_policy_json = data.aws_iam_policy_document.lambda_policy.json
  env_variables = {
    AWS_S3_SFN_TMP_BUCKET = "${var.data_lake_sfn_bucket.s3_bucket_id}"
    AWS_S3_REGION = "${data.aws_region.current.name}"
    API_SECRETS   = "${data.aws_secretsmanager_secret.api_secret_creds.id}"
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
      "${var.data_lake_sfn_bucket.s3_bucket_arn}"
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
      "${var.data_lake_sfn_bucket.s3_bucket_arn}/*"
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets"
    ]
    resources = [
      "${data.aws_secretsmanager_secret.api_secret_creds.arn}"
    ]
  }
}
