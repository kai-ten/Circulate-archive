data "terraform_remote_state" "vpc_output" {
  backend = "s3"
  config = {
    bucket = "${var.name}-${var.env}-terraform-state-backend"
    key    = "vpc/terraform.tfstate"
    region = "us-east-2"
  }
}

module "circulate_create_database" {
  source          = "../../../modules/go-lambda"
  name            = "${var.name}-${var.env}"
  lambda_name     = "${var.name}-${var.env}-${var.service}-lamba"
  src_path        = "../../../../../lib/utils/database-configurator/create-database"
  iam_policy_json = data.aws_iam_policy.AWSLambdaVPCAccessExecutionRole.policy
  timeout = 5
  vpc_config = {
    security_group_ids = [data.terraform_remote_state.vpc_output.outputs.vpc_security_group_id]
    subnet_ids = data.terraform_remote_state.vpc_output.outputs.vpc_public_subnets
  }
}

data "aws_iam_policy" "AWSLambdaVPCAccessExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# resource "null_resource" "db_setup" {
#   triggers = {
#     file = filesha1("../../../../../lib/utils/database-configurator/create-database/assets/main")
#   }
#   provisioner "local-exec" {
#     command = <<-EOF
# 			aws lambda invoke --function-name "$FUNCTION_NAME" /dev/stdout 2>/dev/null
# 			EOF
#     environment = {
#       FUNCTION_NAME     = module.circulate_create_database.lambda_function.function_name
#     }
#     interpreter = ["bash", "-c"]
#   }

#   depends_on = [
#     module.circulate_create_database
#   ]
# }
