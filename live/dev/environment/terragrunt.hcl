terraform {
  source = "${path_relative_from_include()}/../..//environment"
}

inputs = {
  name = "circulate"
  env = "dev"
  vpc_cidr = "10.0.0.0/16"
  is_public = true
}

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
  path = find_in_parent_folders()
}