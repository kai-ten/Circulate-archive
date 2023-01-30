variable "lambda_name" {
  description = "Name of your lambda"
  type        = string
}

variable "vpc_config" {
  description = "optional vpc of your lambda"
  type = object({
    vpc_id = string
    private_subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "db_secret_name" {
  description = "Secret Name for the Database - secret retrieved within lambda"
  type        = string
}

variable "db_secret_arn" {
  description = "Secret arn for the Database - secret retrieved within lambda"
  type        = string
}

variable "data_lake_iac_bucket_name" {
  description = "IaC Bucket name containing the dbt files"
  type        = string
}

variable "data_lake_iac_bucket_arn" {
  description = "IaC Bucket arn containing the dbt files"
  type        = string
}

variable "data_lake_iac_key" {
  description = "Path to your lambda sources"
  type        = string
}

variable "efs_arn" {
  description = "EFS arn for dbt files"
  type        = string
}

variable "efs_mount_path" {
  description = "EFS mount path for dbt files per service"
  type        = string
}

variable "access_point_arn" {
  description = "EFS AP arn for dbt files"
  type        = string
}
