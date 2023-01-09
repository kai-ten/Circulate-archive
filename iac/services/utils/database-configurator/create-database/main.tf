module "circulate_create_database" {
  source          = "../../../modules/go-lambda"
  name            = "${var.name}-${var.env}"
  lambda_name     = "${var.name}-${var.env}-${var.service}-lamba"
  src_path        = "../../../../../lib/utils/database-configurator/create-database"
  iam_policy_json = data.aws_iam_policy_document.example-ssm-secrets.json
  env_variables = {}
}

// TODO: Create empty policy if no further policies are needed, determine whether custom policies are needed or not
data "aws_iam_policy_document" "example-ssm-secrets" {
  statement {
    effect = "Allow"
    actions = [
      "none:null"
    ]
    resources = [
      "*"
    ]
  }
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
