variable "name" {
  description = "Name of your environment"
  type        = string
}

variable "lambda_name" {
  description = "Name of your lambda"
  type        = string
}

variable "env_variables" {
  description = "Environments variables for your lambda"
  type        = map(string)
}

variable "iam_policy_json" {
  description = "IAM policy of your lambda"
  type        = string
}

variable "src_path" {
  description = "Path to your lambda sources"
  type        = string
}

variable "timeout" {
  description = "Execution timeout of your lambda"
  default     = 60
  type        = number
}
