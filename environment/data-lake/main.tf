// This bucket is intended for long term storage in S3, used as a data lake before being loaded downstream to other tools. 
// Must be defined as a target in a union
module "circulate_data_lake" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket            = "${var.name}-${var.env}-data"
  block_public_acls = true

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

resource "aws_s3_bucket_public_access_block" "circulate_data_lake_private" {
  bucket = module.circulate_data_lake.s3_bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// This bucket holds temp data for step functions during the source API call
// This data is then removed after 3 days
module "circulate_data_lake_sfn_tmp" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket            = "${var.name}-${var.env}-sfn-tmp"
  block_public_acls = true

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

resource "aws_s3_bucket_public_access_block" "circulate_data_lake_sfn_tmp_private" {
  bucket = module.circulate_data_lake_sfn_tmp.s3_bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
