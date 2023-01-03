resource "aws_iam_role" "circulate_lambda_role" {
  name = "okta-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Principal = {
          Service = [
            "lambda.amazonaws.com",
          ]
        }
        Action = [
          "sts:AssumeRole"
        ]
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_policy" "circulate_lambda_iam_policy" {
  name        = "okta-lambda-policy"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    # TODO: Make policy more restrictive
    Statement = [
      {
        Action = [
          "s3:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:*:*:*",
        ]
      },
      {
        Action = [
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = "${data.aws_kms_key.aws_s3_kms.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.circulate_lambda_role.name
  policy_arn = aws_iam_policy.circulate_lambda_iam_policy.arn
}

data "archive_file" "zip_okta_lambda" {
  type = "zip"
  source_dir = "./../lib/python/okta"
  output_path = "./../lib/assets/okta.zip"
}

resource "aws_lambda_function" "okta_lambda" {
  filename   = "./../lib/assets/okta.zip"
  function_name = "okta_users_api"
  handler = "handler.lambda_handler"
  role = aws_iam_role.circulate_lambda_role.arn
  runtime = "python3.9"
  architectures = [ "x86_64" ]
  memory_size = 1024
  timeout = 300
  layers = [
    "${aws_lambda_layer_version.circulate_okta_libs_python39.arn}"
  ]
}

resource "aws_lambda_layer_version" "circulate_okta_libs_python39" {
  filename = "./../lib/assets/okta-libs.zip"
  layer_name = "circulate-okta-libspython39"
  source_code_hash = " ${filebase64sha256("./../lib/assets/okta-libs.zip")}"
  compatible_runtimes = [ "python3.9" ]
}

resource "aws_iam_role" "step_functions_role" {
  name = "step_functions_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "step_functions_policy" {
  name = "step-functions-policy"
  role = aws_iam_role.step_functions_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "states:ListStateMachines",
        "states:ListExecutions",
        "states:StartExecution",
        "states:DescribeExecution",
        "states:StopExecution",
        "states:GetExecutionHistory"
      ],
      "Resource": "*"
    },
    {
      "Action": "lambda:InvokeFunction",
      "Resource": [
        "${aws_lambda_function.okta_lambda.arn}",
        "${aws_lambda_function.okta_lambda.arn}:*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_sfn_state_machine" "step_function" {
  name        = "okta_get_users"
  role_arn = aws_iam_role.step_functions_role.arn
  definition  = <<DEFINITION
{
  "StartAt": "RetrieveData",
  "States": {
    "RetrieveData": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.okta_lambda.arn}",
      "Next": "Pass"
    },
    "Pass": {
      "Type": "Pass",
      "End": true
    }
  }
}
DEFINITION
}

resource "aws_cloudwatch_event_rule" "okta_event_rule" {
  name        = "okta_event_rule"
  description = "Event rule to trigger okta_lambda every 5 minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "okta_event_target" {
  target_id = "okta_event_target"
  rule      = aws_cloudwatch_event_rule.okta_event_rule.name
  arn       = aws_sfn_state_machine.step_function.arn
  role_arn = aws_iam_role.step_functions_role.arn
}

    # ,
     # "Next": "StoreData"
    # "StoreData": {
    #   "Type": "Task",
    #   "Resource": "${aws_lambda_function.store_data.arn}",
    #   "End": true
    # }