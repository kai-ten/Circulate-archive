module "circulate_data_bucket" {
  source      = "./modules/s3"
  bucket_name = var.data_s3_bucket
}