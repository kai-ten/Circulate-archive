data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Example - https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/examples/complete-vpc/main.tf
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

  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "integration_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name   = "${var.name}-${var.env}_sg_idv2"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "SSL Traffic"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id

  endpoints = {
    ssm = {
      service             = "secretsmanager"
      security_group_ids = [module.integration_security_group.security_group_id]
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags    = { Name = "${var.name}-${var.env}-ssm" }
    }
    # s3 = {
    #   service             = "com.amazonaws.${data.aws_region.current.name}.s3"
    #   route_table_ids     = module.vpc.public_route_table_ids
    #   tags    = { Name = "${var.name}-${var.env}-s3" }
    # }
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = module.vpc.vpc_id
  service_name    = "com.amazonaws.${data.aws_region.current.name}.s3"
  route_table_ids = concat(module.vpc.public_route_table_ids, module.vpc.private_route_table_ids)

  tags = {
    Name = "${var.name}-${var.env}-s3"
  }
}
