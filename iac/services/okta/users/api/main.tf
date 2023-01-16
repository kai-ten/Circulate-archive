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

data "aws_secretsmanager_secret" "vpc_secret" {
  name = data.terraform_remote_state.vpc_output.outputs.api_secrets_name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "go-lambda" {
  source          = "../../../modules/go-lambda"
  name            = "${var.name}-${var.env}"
  lambda_name     = "${var.name}-${var.env}-${var.service}"
  src_path        = "../../../../../lib/okta/users/api"
  iam_policy_json = data.aws_iam_policy_document.lambda_policy.json
  env_variables = {
    AWS_S3_BUCKET = "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3.s3_bucket_id}"
    AWS_S3_REGION = "${data.aws_region.current.name}"
    API_SECRETS = "${data.terraform_remote_state.vpc_output.outputs.api_secrets_name}"
  }
}

// TODO: Create empty policy if no further policies are needed, determine whether custom policies are needed or not
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
      "s3:DeleteObject",
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
      "${data.aws_secretsmanager_secret.vpc_secret.arn}"
    ]
  }
}

locals {
  definition_template = <<EOF
{
  "Comment": "Retrieve the Okta Users API data",
  "StartAt": "Okta Users API",
  "States": {
    "Okta Users API": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${module.go-lambda.lambda_function.arn}:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "End": true
    }
  }
}
EOF
}

module "step_function" {
  source = "terraform-aws-modules/step-functions/aws"

  name       = "my-step-function"
  definition = local.definition_template

  service_integrations = {
    lambda = {
      lambda = ["${module.go-lambda.lambda_function.arn}:*"]
    }

    # TODO: Adjust to use region, account number, and generate step function name AOT
    stepfunction_Sync = {
      stepfunction          = ["arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:my-step-function"]
      stepfunction_Wildcard = ["arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:my-step-function"]

      # Set to true to use the default events (otherwise, set this to a list of ARNs; see the docs linked in locals.tf
      # for more information). Without events permissions, you will get an error similar to this:
      #   Error: AccessDeniedException: 'arn:aws:iam::xxxx:role/step-functions-role' is not authorized to
      #   create managed-rule
      events = true
    }
  }

  type = "STANDARD"

  tags = {
    Module = "my"
  }
}
