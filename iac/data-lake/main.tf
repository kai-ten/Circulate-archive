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
