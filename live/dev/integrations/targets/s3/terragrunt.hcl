terraform {
  source = "${path_relative_from_include()}/integrations//targets/s3"
}

dependency "environment" {
  config_path = "../../../environment"
}

locals {
  circulate_vars = read_terragrunt_config("../../../circulate.hcl")
}

inputs = merge(
  local.circulate_vars.inputs,
  {
    data_lake_sfn_bucket = dependency.environment.outputs.data_lake_s3_sfn_tmp
    data_lake_bucket = dependency.environment.outputs.data_lake_s3
  }
)

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite"
  contents = <<EOF
provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Project = "Circulate"
      Module  = "targets"
    }
  }
}
EOF
}

include "root" {
  path = find_in_parent_folders()
}
