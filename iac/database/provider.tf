terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.45"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"

  default_tags {
    tags = {
      Project = "Circulate"
      Module  = "database"
    }
  }
}
