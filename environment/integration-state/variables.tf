variable "name" {
  type    = string
  default = "circulate"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "table_name" {
  type = string
}

variable "billing_mode" {
  type = string
}

variable "read_capacity" {
  type = number
}

variable "write_capacity" {
  type = number
}

variable "hash_key" {
  type = string

}

variable "range_key" {
  type = string
}

variable "encryption" {
  type = object({
    enabled = bool
    kms_key_arn = optional(string)
  })
}

variable "attributes" {
  type = list(object({
    name = string
    type = string
  }))
}

variable "ttl" {
  type = object({
    attribute_name = string
    enabled        = bool
  })
}

variable "global_secondary_indexes" {
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    write_capacity     = optional(number)
    read_capacity      = optional(number)
    projection_type    = string
    non_key_attributes = optional(list(string))
  }))
}
