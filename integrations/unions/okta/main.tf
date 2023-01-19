data "terraform_remote_state" "okta_sources" {
  backend = "s3"
  config = {
    bucket = "${var.name}-${var.env}-terraform-state-backend"
    key    = "okta_sources/terraform.tfstate"
    region = "us-east-2"
  }
}

# data "terraform_remote_state" "postgresdb_output" {
#   backend = "s3"
#   config = {
#     bucket = "${var.name}-${var.env}-terraform-state-backend"
#     key    = "postgresdb/terraform.tfstate"
#     region = "us-east-2"
#   }
# }

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
        "FunctionName": "${data.terraform_remote_state.okta_sources.outputs.lambda_function.arn}:$LATEST"
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

# "Next": "Okta Users Database"
# "Okta Users Database": {
#   "Type": "Task",
#   "Resource": "arn:aws:states:::lambda:invoke",
#   "OutputPath": "$.Payload",
#   "Parameters": {
#     "Payload.$": "$",
#     "FunctionName": "${module.okta_database.lambda_function.arn}:$LATEST"
#   },
#   "Retry": [
#     {
#       "ErrorEquals": [
#         "Lambda.ServiceException",
#         "Lambda.AWSLambdaException",
#         "Lambda.SdkClientException",
#         "Lambda.TooManyRequestsException"
#       ],
#       "IntervalSeconds": 2,
#       "MaxAttempts": 6,
#       "BackoffRate": 2
#     }
#   ],
#   "End": true
# }

module "step_function" {
  source = "terraform-aws-modules/step-functions/aws"

  name       = var.service
  definition = local.definition_template

  service_integrations = {
    lambda = {
      lambda = [
        "${module.okta_api.lambda_function.arn}:*",
        # "${module.okta_database.lambda_function.arn}:*",
      ]
    }

    # TODO: Adjust to use region, account number, and generate step function name AOT
    stepfunction_Sync = {
      stepfunction          = ["arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.sfn_name}"]
      stepfunction_Wildcard = ["arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.sfn_name}"]

      # Set to true to use the default events (otherwise, set this to a list of ARNs; see the docs linked in locals.tf
      # for more information). Without events permissions, you will get an error similar to this:
      #   Error: AccessDeniedException: 'arn:aws:iam::xxxx:role/step-functions-role' is not authorized to
      #   create managed-rule
      events = true
    }
  }

  type = "STANDARD"
}
