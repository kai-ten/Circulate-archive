variable "name" {
  description = "Name of your lambda"
  type        = string
}

variable "env" {
  description = "Environments variables for your lambda"
  type        = string
}

variable "service" {
  description = "Service name for the API"
  type        = string
}

variable "dbt_key" {
  description = "Service name for the API"
  type        = string
}
