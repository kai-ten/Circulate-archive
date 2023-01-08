data "aws_secretsmanager_secret" "circulatedb_api_secret" {
  name = "/${var.name}-${var.env}/api/integrations"
}

data "aws_secretsmanager_secret_version" "circulatedb_api_secret_version" {
  secret_id = data.aws_secretsmanager_secret.circulatedb_api_secret.id
}

module "go-lambda" {
  source          = "../modules/go-lambda"
  name            = "${var.name}-${var.env}"
  lambda_name     = "${var.name}-${var.env}-${var.service}-lamba"
  src_path        = "../../../lib/okta"
  iam_policy_json = data.aws_iam_policy_document.example-ssm-secrets.json
  env_variables = {
    OKTA_URL     = "${jsondecode(data.aws_secretsmanager_secret_version.circulatedb_api_secret_version.secret_string)["okta_url"]}"
    OKTA_API_KEY = "${jsondecode(data.aws_secretsmanager_secret_version.circulatedb_api_secret_version.secret_string)["okta_api_key"]}"
  }
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
