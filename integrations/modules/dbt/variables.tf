variable "name" {
  description = "Name of service"
  type        = string
}

variable "env" {
  description = "Env of service"
  type        = string
}

variable "region" {
  description = "Region of the infrastructure"
  type        = string
}

variable "lambda_name" {
  description = "Name of your lambda"
  type        = string
}

variable "service" {
  description = "Service name for EFS"
  type        = string
}

variable "vpc_config" {
  description = "optional vpc of your lambda"
  type = object({
    vpc_id = string
    private_subnet_ids = list(string)
    security_group_id = string
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

variable "efs_id" {
  description = "The EFS Id to create an Access Point for"
  type = string
}

variable "efs_arn" {
  description = "EFS arn for dbt files"
  type        = string
}

variable "efs_sg_id" {
  description = "EFS security group id"
  type        = string
}

variable "ecs_cluster_id" {
  type = string
}

# variable "task_definition" {
#   type = object({
#     cpu = string
#     memory = string
#     mount_point = string
#     volume_name = string
#     port_mappings = list(object({
#       name = string
#       protocol = string
#       containerPort = number
#       hostPort = number
#     }))
#   })
# }
