variable "name" {
  description = "Name of your lambda"
  type        = string
}

variable "env" {
  description = "Environments variables for your lambda"
  type        = string
}

variable "enabled" {
  description = "Build lambda if enabled"
  type        = bool
  default = false
}

variable "service" {
  description = "Service name for your lambda"
  type        = string
}

variable "endpoint" {
  description = "Endpoint name for your lambda"
  type        = string
}

variable "data_lake_sfn_bucket" {
  description = "Bucket SFN bucket config"
  type = map
}

variable "data_lake_bucket" {
  description = "Bucket S3 bucket config"
  type = map
}

variable "src_path" {
  description = "Path to your lambda source"
  type        = string
}
