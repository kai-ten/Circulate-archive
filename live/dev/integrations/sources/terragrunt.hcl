terraform {
  source = "${path_relative_from_include()}/integrations//sources"
}

dependency "environment" {
  config_path = "../../environment"
}

locals {
  common_vars = read_terragrunt_config("../../common.hcl")
}

inputs = merge(
  local.common_vars.inputs,
  {
    data_lake_sfn_bucket = dependency.environment.outputs.data_lake_s3_sfn_tmp
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
      Module  = "sources"
    }
  }
}
EOF
}

include "root" {
  path = find_in_parent_folders()
}