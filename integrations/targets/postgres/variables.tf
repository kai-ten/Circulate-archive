variable "name" {
  description = "Name of your lambda"
  type        = string
}

variable "env" {
  description = "Environments variables for your lambda"
  type        = string
}

variable "targets" {
  description = "Path to Target lambda code"
  type = map
}

variable "data_lake_sfn_bucket" {
  description = "Bucket SFN bucket config"
  type = map
  default = {
    name  = ""
    arn   = ""
  }
}

variable "integration_security_group_id" {
  description = "Security group for VPC"
  type        = string
}

variable "vpc_private_subnets" {
  description = "Private subnets for VPC"
  type        = list
}

variable "database_secret_name" {
  description = "Postgres DB Secret Name"
  type        = string
}
