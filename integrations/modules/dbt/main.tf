data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "dbt_lambda_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name   = "${var.name}-${var.env}_dbt_lambda_sg"
  vpc_id = var.vpc_config.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "S3 Outbound Access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "EFS Outbound Access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = "10.0.0.0/16"
    }
  ]
}

resource "aws_efs_access_point" "dbt_ap" {
  file_system_id = var.efs_id

  posix_user {
    gid = 1000
    uid = 1000
    secondary_gids = [ 1001 ]
  }
  root_directory {
    path = "/${var.service}"
    creation_info {
      owner_gid = 1000
      owner_uid = 1000
      permissions = "777"
    }
  }
}

module "dbt_profiles_generator" {
  source          = "../go-lambda"
  name            = "${var.lambda_name}"
  lambda_name     = "${var.lambda_name}"
  src_path        = "../lib"
  iam_policy_json = data.aws_iam_policy_document.lambda_policy.json
  timeout = 5

  vpc_config = {
    security_group_ids = [module.dbt_lambda_security_group.security_group_id]
    subnet_ids = var.vpc_config.private_subnet_ids
  }

  env_variables = {
    AWS_S3_REGION = "${data.aws_region.current.name}"
    DATABASE_SECRET = "${var.db_secret_name}"
    AWS_S3_DATA_LAKE_IAC_BUCKET = "${var.data_lake_iac_bucket_name}"
    AWS_S3_DATA_LAKE_IAC_KEY = "${var.data_lake_iac_key}"
    EFS_MOUNT_PATH = "/mnt/${var.service}/"
  }

  efs_config = {
    arn = aws_efs_access_point.dbt_ap.arn
    mount_path = "/mnt/${var.service}"
  }

  depends_on = [
    aws_efs_access_point.dbt_ap
  ]
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
      "s3:PutObjectAcl",
      "s3:GetObjectAcl"
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
      values = ["${aws_efs_access_point.dbt_ap.arn}"]
    }
  }
}

