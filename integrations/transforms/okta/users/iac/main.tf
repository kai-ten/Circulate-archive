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

resource "aws_s3_bucket_object" "okta_users_dbt_files" {
  for_each = fileset("../dbt", "**")
  bucket = "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_iac.s3_bucket_id}"
  key = "${var.dbt_key}${each.value}"
  source = "../dbt/${each.value}"
  etag = filemd5("../dbt/${each.value}")
}

# TODO: Better practice to generate KMS key to encrypt message in transit - establish pattern to create this key in environment config
resource "aws_sns_topic" "dbt_generator_topic" {
  name = "${var.name}-${var.env}-${var.service}-generator-topic"
  
  policy = <<POLICY
  {
      "Version":"2012-10-17",
      "Statement":[
        {
          "Effect": "Allow",
          "Principal": {"Service":"s3.amazonaws.com"},
          "Action": "SNS:Publish",
          "Resource":  "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.name}-${var.env}-${var.service}-generator-topic",
          "Condition":{
              "ArnLike":{"aws:SourceArn":"${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_iac.s3_bucket_arn}"}
          }
        }
      ]
  }
  POLICY
}

resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = "${data.terraform_remote_state.data_lake_output.outputs.data_lake_s3_iac.s3_bucket_id}"

  topic {
    topic_arn = "${aws_sns_topic.dbt_generator_topic.arn}"
    events = [
      "s3:ObjectCreated:*",
      "s3:ObjectRemoved:*",
    ]
  }
}

module "dbt_profiles_generator" {
  source          = "../../../../modules/dbt"
  name = var.name
  env = var.env
  region = "${data.aws_region.current.name}"
  service = "${var.service}"
  lambda_name = "${var.name}-${var.env}-${var.service}-generator"
  ecs_cluster_id = data.terraform_remote_state.data_lake_output.outputs.dbt_ecs_cluster.id
  
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

resource "aws_lambda_permission" "dbt_generator_sns" {
    statement_id = "AllowExecutionFromSNS"
    action = "lambda:InvokeFunction"
    function_name = "${module.dbt_profiles_generator.lambda_function.arn}"
    principal = "sns.amazonaws.com"
    source_arn = "${aws_sns_topic.dbt_generator_topic.arn}"
}

resource "aws_sns_topic_subscription" "dbt_topic_sub" {
  topic_arn = "${aws_sns_topic.dbt_generator_topic.arn}"
  protocol  = "lambda"
  endpoint  ="${module.dbt_profiles_generator.lambda_function.arn}"
}
