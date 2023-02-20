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

variable "src_path" {
  description = "Path to Source lambda code"
  type        = string
  default = ""
}

variable "secret_name" {
  description = "Secret for Source privileged access"
  type        = string
  default = ""
}

variable "data_lake_sfn_bucket" {
  description = "Bucket config"
  type = map
  default = {
    name  = ""
    arn   = ""
  }
}
