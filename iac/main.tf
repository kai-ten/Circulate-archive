data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_kms_key" "aws_s3_kms" {
  key_id = "alias/aws/s3"
}
