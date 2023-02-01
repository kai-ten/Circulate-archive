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

resource "aws_s3_bucket_object" "okta_users_dbt_files" {
  for_each = fileset("../dbt", "**")
  bucket = "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_iac.s3_bucket_id}"
  key = "${var.dbt_key}${each.value}"
  source = "../dbt/${each.value}"
  etag = filemd5("../dbt/${each.value}")
}

module "dbt_profiles_generator" {
  source          = "../../../../modules/dbt-lambda"
  name = var.name
  env = var.env
  region = "${data.aws_region.current.name}"
  service = "${var.service}"
  lambda_name = "${var.name}-${var.env}-${var.service}-generator"
  
  vpc_config = {
    vpc_id = data.terraform_remote_state.vpc_output.outputs.vpc_id
    security_group_id = data.terraform_remote_state.vpc_output.outputs.integration_security_group_id
    private_subnet_ids = data.terraform_remote_state.vpc_output.outputs.vpc_private_subnets
  }

  data_lake_iac_bucket_arn = data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_iac.s3_bucket_arn
  data_lake_iac_bucket_name = data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_iac.s3_bucket_id
  data_lake_iac_key = "${var.dbt_key}"

  db_secret_arn = data.aws_secretsmanager_secret.postgres_secret.arn
  db_secret_name = "${data.terraform_remote_state.vpc_output.outputs.database_secret_name}"

  efs_id = data.terraform_remote_state.data_lake_output.outputs.data_lake_efs.id
  efs_arn = data.terraform_remote_state.data_lake_output.outputs.data_lake_efs.arn
  efs_sg_id = data.terraform_remote_state.data_lake_output.outputs.data_lake_efs.security_group_id
}
