module "dynamodb_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name                           = "${var.name}-${var.env}-${var.table_name}"
  billing_mode                   = var.billing_mode
  server_side_encryption_enabled = var.server_side_encryption_enabled

  hash_key = var.hash_key

  attributes = [
    {
      name = "id"
      type = "N"
    }
  ]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table_item
# resource "aws_dynamodb_table_item" "example" {
#   table_name = aws_dynamodb_table.example.name
#   hash_key   = aws_dynamodb_table.example.hash_key

#   item = <<ITEM
# {
#   "exampleHashKey": {"S": "something"},
#   "one": {"N": "11111"},
#   "two": {"N": "22222"},
#   "three": {"N": "33333"},
#   "four": {"N": "44444"}
# }
# ITEM
# }