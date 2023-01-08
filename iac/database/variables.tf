variable "name" {
  type    = string
  default = "circulate"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "is_public" {
  type    = bool
  default = false
}

variable "instance_type" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

variable "is_multi_az" {
  type    = bool
  default = false
}
