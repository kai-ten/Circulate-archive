terraform {
  required_version = ">= 1.3"

  backend "s3" {
    bucket         = "circulate-dev-terraform-state-backend"
    key            = "okta/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform_state"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.45"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"

  default_tags {
    tags = {
      Project = "Circulate"
      Module  = "services"
    }
  }
}