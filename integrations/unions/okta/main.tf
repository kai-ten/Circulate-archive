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

data "terraform_remote_state" "okta_users" {
  backend = "s3"
  config = {
    bucket = "${var.name}-${var.env}-terraform-state-backend"
    key    = "okta_users/terraform.tfstate"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "okta_users_transform" {
  backend = "s3"
  config = {
    bucket = "${var.name}-${var.env}-terraform-state-backend"
    key    = "okta-users-transform/terraform.tfstate"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "postgres_json_writer_output" {
  backend = "s3"
  config = {
    bucket = "${var.name}-${var.env}-terraform-state-backend"
    key    = "postgres-json-writer/terraform.tfstate"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "s3_writer_output" {
  backend = "s3"
  config = {
    bucket = "${var.name}-${var.env}-terraform-state-backend"
    key    = "s3-json-writer/terraform.tfstate"
    region = "us-east-2"
  }
}

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
        "FunctionName": "${data.terraform_remote_state.okta_users.outputs.okta_api_lambda.arn}:$LATEST"
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
      "Next": "Write To Targets"
    },
    "Write To Targets": {
      "Type": "Parallel",
      "End": true,
      "Branches": [
        {
          "StartAt": "S3 Json Writer",
          "States": {
            "S3 Json Writer": {
              "Type": "Task",
              "Resource": "arn:aws:states:::lambda:invoke",
              "OutputPath": "$.Payload",
              "Parameters": {
                "Payload.$": "$",
                "FunctionName": "${data.terraform_remote_state.s3_writer_output.outputs.s3_writer.arn}:$LATEST"
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
        },
        {
          "StartAt": "Postgres Json Writer",
          "States": {
            "Postgres Json Writer": {
              "Type": "Task",
              "Resource": "arn:aws:states:::lambda:invoke",
              "OutputPath": "$.Payload",
              "Parameters": {
                "Payload.$": "$",
                "FunctionName": "${data.terraform_remote_state.postgres_json_writer_output.outputs.postgres_json_writer.arn}:$LATEST"
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
              "Next": "Run dbt"
            },
            "Run dbt": {
              "Type": "Task",
              "Resource": "arn:aws:states:::ecs:runTask.sync",
              "Parameters": {
                "LaunchType": "FARGATE",
                "Cluster": "${data.terraform_remote_state.data_lake_output.outputs.dbt_ecs_cluster.arn}",
                "TaskDefinition": "${data.terraform_remote_state.okta_users_transform.outputs.ecs_task_def_arn}",
                "NetworkConfiguration": {
                  "AwsvpcConfiguration": {
                    "Subnets": ${jsonencode(data.terraform_remote_state.vpc_output.outputs.vpc_private_subnets)},
                    "SecurityGroups": ["${data.terraform_remote_state.okta_users_transform.outputs.security_group_id}"]
                  }
                }
              },
              "End": true
            }
          }
        }
      ]
    }
  }
}
EOF
}

module "step_function" {
  source = "terraform-aws-modules/step-functions/aws"

  name       = var.sfn_name
  definition = local.definition_template

  service_integrations = {
    lambda = {
      lambda = [
        "${data.terraform_remote_state.okta_users.outputs.okta_api_lambda.arn}:*",
        "${data.terraform_remote_state.postgres_json_writer_output.outputs.postgres_json_writer.arn}:*",
        "${data.terraform_remote_state.s3_writer_output.outputs.s3_writer.arn}:*",
      ]
    }

    ecs_Sync = {
      ecs = [
        "${data.terraform_remote_state.data_lake_output.outputs.dbt_ecs_cluster.arn}",
        "${data.terraform_remote_state.okta_users_transform.outputs.ecs_task_def_arn}",
      ]

      ecs_Wildcard = [
        "${data.terraform_remote_state.data_lake_output.outputs.dbt_ecs_cluster.arn}",
        "${data.terraform_remote_state.okta_users_transform.outputs.ecs_task_def_arn}",
      ]

      iam_PassRole = [
        "${data.terraform_remote_state.okta_users_transform.outputs.task_exec_role_arn}",
        "${data.terraform_remote_state.okta_users_transform.outputs.task_role_arn}",
      ]

      events = true
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
