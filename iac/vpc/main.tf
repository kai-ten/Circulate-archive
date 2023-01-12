data "aws_availability_zones" "available" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${var.name}-${var.env}"
  cidr = var.vpc_cidr

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 6)]

  create_database_subnet_group           = var.is_public
  create_database_subnet_route_table     = var.is_public
  create_database_internet_gateway_route = var.is_public

  enable_dns_hostnames = var.is_public
  enable_dns_support   = var.is_public
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name   = "${var.name}-${var.env}_sg_id"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]
}

# module "endpoints" {
#   source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

#   vpc_id             = module.vpc.vpc_id
#   security_group_ids = [module.security_group.security_group_id]
#   subnet_ids         = module.vpc.database_subnets


#   endpoints = {
#     lambda = {
#       service = "lambda"
#       tags    = { Name = "${var.name}-${var.env}-lambda-vpc-endpoint" }
#       private_dns_enabled = true
#     }
#   }
# }
