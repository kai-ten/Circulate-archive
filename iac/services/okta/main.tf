module "go-lambda" {
  source          = "../modules/go-lambda"
  name            = "${var.name}-${var.env}"
  lambda_name     = "${var.name}-${var.env}-${var.service}-lamba"
  src_path        = "../../../lib/okta"
  iam_policy_json = data.aws_iam_policy_document.example-ssm-secrets.json
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
