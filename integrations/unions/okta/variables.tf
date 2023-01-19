variable "name" {
  description = "Name of your lambda"
  type        = string
}

variable "env" {
  description = "Environments variables for your lambda"
  type        = string
}

variable "sfn_name" {
  description = "Service name for your lambda"
  type        = string
}
