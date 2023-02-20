data "aws_caller_identity" "current" {}

module "s3_writer" {

  count = (var.enabled && var.endpoint == "s3") == true ? 1 : 0
  
  source          = "../../../modules/go-lambda"
  name            = "${var.name}-${var.env}-${var.service}"
  lambda_name     = "${var.name}-${var.env}-${var.service}"
  src_path        = "${var.src_path}"
  iam_policy_json = data.aws_iam_policy_document.lambda_policy.json
  timeout = 5
  env_variables = {
    SOURCE_BUCKET = "${var.data_lake_sfn_bucket.s3_bucket_id}"
    TARGET_BUCKET = "${var.data_lake_bucket.s3_bucket_id}"
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${var.data_lake_sfn_bucket.s3_bucket_arn}",
      "${var.data_lake_bucket.s3_bucket_arn}"
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
      "${var.data_lake_sfn_bucket.s3_bucket_arn}/*",
      "${var.data_lake_bucket.s3_bucket_arn}/*"
    ]
  }
}
