module "dbt_lambda_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name   = "${var.name}-${var.env}_dbt_lambda_sg"
  vpc_id = var.vpc_id

  egress_with_source_security_group_id = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS for S3 and Secrets Manager"
      source_security_group_id = data.terraform_remote_state.vpc_outputs.integration_security_group_id
    },
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "EFS access from Lambda"
      source_security_group_id = var.efs_sg_id
    },
    
  ]
}

module "dbt_profiles_generator" {
  source          = "../go-lambda"
  name            = "${var.lambda_name}"
  lambda_name     = "${var.lambda_name}"
  src_path        = "../lib"
  iam_policy_json = data.aws_iam_policy_document.lambda_policy.json
  timeout = 5
  vpc_config = {
    security_group_ids = [var.vpc.security_group_ids, dbt_lambda_security_group.security_group_id]
    subnet_ids = var.vpc.private_subnet_ids
  }
  env_variables = {
    AWS_S3_REGION = "${data.aws_region.current.name}"
    DATABASE_SECRET = "${var.db_secret_name}"
    AWS_S3_DATA_LAKE_IAC_BUCKET = "${var.data_lake_iac_bucket_name}"
    AWS_S3_DATA_LAKE_IAC_KEY = "${var.data_lake_iac_key}"
  }
  efs_config = {
    arn = "${var.efs_arn}"
    mount_path = "${var.efs_mount_path}"
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${var.data_lake_iac_bucket_arn}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${var.data_lake_iac_bucket_arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets"
    ]
    resources = [
      "${var.db_secret_arn}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]
    resources = [
      "${var.efs_arn}"
    ]
    condition {
      test = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values = ["${var.access_point_arn}"]
    }
  }
}

