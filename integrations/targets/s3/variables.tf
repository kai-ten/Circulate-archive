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
  type        = map
}

variable "data_lake_sfn_bucket" {
  description = "Bucket SFN bucket config"
  type = map
  default = {
    name  = ""
    arn   = ""
  }
}

variable "data_lake_bucket" {
  description = "Bucket S3 bucket config"
  type = map
  default = {
    name  = ""
    arn   = ""
  }
}
