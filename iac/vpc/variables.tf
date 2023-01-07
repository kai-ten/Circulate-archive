variable "name" {
  type    = string
  default = "circulate"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "is_public" {
  type    = bool
  default = false
}
