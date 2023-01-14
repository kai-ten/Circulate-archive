module "go-lambda" {
  source          = "../../../modules/go-lambda"
  name            = "${var.name}-${var.env}"
  lambda_name     = "${var.name}-${var.env}-${var.service}"
  src_path        = "../../../../../lib/okta/users/api"
  iam_policy_json = data.aws_iam_policy_document.lambda_policy.json
}

// TODO: Create empty policy if no further policies are needed, determine whether custom policies are needed or not
data "aws_iam_policy_document" "lambda_policy" {
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
      stepfunction          = ["arn:aws:states:us-east-2:298203888315:stateMachine:my-step-function"]
      stepfunction_Wildcard = ["arn:aws:states:us-east-2:298203888315:stateMachine:my-step-function"]

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
