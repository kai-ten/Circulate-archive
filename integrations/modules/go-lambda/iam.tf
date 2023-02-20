resource "aws_iam_role" "lambda" {
  name_prefix = "${var.lambda_name}-lambda"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = "sts:AssumeRole",
          Principal = {
            Service = "lambda.amazonaws.com"
          },
          Effect = "Allow",
        }
      ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name_prefix = "${var.lambda_name}-lambda"
  role   = aws_iam_role.lambda.id
  policy = var.iam_policy_json
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_policy" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
