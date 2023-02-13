// This bucket is intended for long term storage in S3, used as a data lake before being loaded downstream to other tools. 
// Must be defined as a target in a union
module "circulate_data_lake" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket            = "${var.name}-${var.env}-data"
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true


  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning = {
    enabled = true
  }
}

// This bucket holds temp data for step functions during the source API call
// This data is then removed after 3 days
module "circulate_data_lake_sfn_tmp" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket            = "${var.name}-${var.env}-sfn-tmp"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  
  lifecycle_rule = [
    {
      id      = "sfn-tmp-data"
      enabled = true

      expiration = {
        days = 3
      }
    }
  ]

  versioning = {
    enabled = true
  }
}

module "circulate_iac" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket            = "${var.name}-${var.env}-iac"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning = {
    enabled = true
  }
}

module "efs" {
  source = "terraform-aws-modules/efs/aws"

  name           = "${var.name}-${var.env}-efs"
  creation_token = "${var.name}-${var.env}-efs"
  encrypted      = true

  performance_mode                = "generalPurpose"
  throughput_mode                 = "bursting"

  # Mount targets are generated to look like:
  # "us-east-2a" = {
  #    subnet_id = "subnet-abcde012"
  #  }
  mount_targets              = { 
    for k, v in zipmap(
      slice(data.aws_availability_zones.available.names, 0, 3), 
      module.vpc.private_subnets
    ) : k => { subnet_id = v } 
  }

  security_group_name = "${var.name}-${var.env}_efs_sg"
  security_group_description = "Circulate EFS security group"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provdied for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }
}

resource "aws_ecs_cluster" "circulate_ecs_cluster" {
  name = "circulate-${var.env}-cluster"
}
