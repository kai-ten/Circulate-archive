variable "name" {
  type    = string
  default = "circulate"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "is_public" {
  type    = bool
  default = false
}

variable "sources" {
  type = map
  default = {}
}
