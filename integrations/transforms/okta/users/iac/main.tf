data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

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

data "aws_secretsmanager_secret" "postgres_secret" {
  name = "${data.terraform_remote_state.vpc_output.outputs.database_secret_name}"
}

resource "aws_ecr_repository" "dbt_postgres_ecr_repo" {
  name                 = "${var.name}-${var.env}-${var.service}-repo"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_repository_policy" "dbt_postgres_ecr_repo_policy" {
  repository = aws_ecr_repository.dbt_postgres_ecr_repo.name
  policy     = <<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "Set the permission for ECR",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  }
  EOF

  provisioner "local-exec" {
    command = <<-EOT
docker image pull ghcr.io/dbt-labs/dbt-postgres:1.2.3

aws ecr get-login-password \
    --region ${data.aws_region.current.name} \
| docker login \
    --username AWS \
    --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com

docker tag ghcr.io/dbt-labs/dbt-postgres:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${aws_ecr_repository.dbt_postgres_ecr_repo.name}

docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${aws_ecr_repository.dbt_postgres_ecr_repo.name}
    EOT
  }
}

# EFS to store 
# Upload the dbt directory to s3 using aws_s3_bucket_object resource
# Create lambda to generate dbt/profiles.yml, then to write the dbt files + profiles.yml from S3 to the EFS
# Build ECS and mount EFS to ECS container/subnet
# ECS must call docker run like here: https://docs.getdbt.com/docs/get-started/docker-install

resource "aws_efs_access_point" "okta_users_dbt_ap" {
  file_system_id = data.terraform_remote_state.data_lake_output.outputs.data_lake_efs.id

  posix_user {
    gid = 1001
    uid = 1001
    secondary_gids = [ 1002 ]
  }
  root_directory {
    path = "/${var.service}"
    creation_info {
      owner_gid = 1001
      owner_uid = 1001
      permissions = "755"
    }
  }
}

resource "aws_s3_bucket_object" "okta_users_dbt_files" {
  for_each = fileset("../dbt", "**")
  bucket = "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_iac.s3_bucket_id}"
  key = "api/okta/users/dbt/${each.value}"
  source = "../dbt/${each.value}"
  etag = filemd5("../dbt/${each.value}")
}

module "dbt_profiles_generator" {
  source          = "../../../../modules/go-lambda"
  name            = "${var.name}-${var.env}-${var.service}-generator"
  lambda_name     = "${var.name}-${var.env}-${var.service}-generator"
  src_path        = "../lib"
  iam_policy_json = data.aws_iam_policy_document.lambda_policy.json
  timeout = 5
  vpc_config = {
    security_group_ids = [data.terraform_remote_state.vpc_output.outputs.vpc_security_group_id]
    subnet_ids = data.terraform_remote_state.vpc_output.outputs.vpc_public_subnets
  }
  env_variables = {
    DATABASE_SECRET = "${data.terraform_remote_state.vpc_output.outputs.database_secret_name}"
    AWS_S3_DATA_LAKE_IAC = "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_iac.s3_bucket_id}"
  }
  efs_config = {
    arn = "${data.terraform_remote_state.data_lake_output.outputs.data_lake_efs.arn}"
    mount_path = "value"
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_iac.s3_bucket_arn}"
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
      "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_iac.s3_bucket_arn}/*"
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
      "${data.aws_secretsmanager_secret.postgres_secret.arn}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]
    resources = [
      "${data.terraform_remote_state.data_lake_output.outputs.data_lake_efs.arn}"
    ]
  }
}
