module "circulate_create_table" {
  source          = "../../../modules/go-lambda"
  name            = "${var.name}-${var.env}"
  lambda_name     = "${var.name}-${var.env}-${var.service}-lamba"
  src_path        = "../../../lib/utils/database-configurator/create-table"
  iam_policy_json = data.aws_iam_policy_document.example-ssm-secrets.json
  env_variables = {}
}

// TODO: Create empty policy if no further policies are needed, determine whether custom policies are needed or not
data "aws_iam_policy_document" "example-ssm-secrets" {
  statement {
    effect = "Allow"
    actions = [
      "none:null"
    ]
    resources = [
      "*"
    ]
  }
}

