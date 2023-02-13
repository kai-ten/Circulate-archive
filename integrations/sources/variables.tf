variable "name" {
  description = "Name of your lambda"
  type        = string
}

variable "env" {
  description = "Environments variables for your lambda"
  type        = string
}

variable "sources" {
  description = "Path to Source lambda code"
  type        = map
}

variable "data_lake_sfn_bucket" {
  description = "Bucket config"
  type = map
}
