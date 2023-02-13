terraform {
  source = "../../..//environment"
}

locals {
  common_vars = read_terragrunt_config("../common.hcl")
}

inputs = merge(
  local.common_vars.inputs,
  {
    vpc_cidr = "10.0.0.0/16"
  }
)

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Project = "Circulate"
      Module  = "environment"
    }
  }
}
EOF
}

include "root" {
  path = "../../../terragrunt.hcl"
}
