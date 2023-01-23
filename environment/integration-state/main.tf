resource "aws_dynamodb_table" "dynamodb-table" {
  name           = "${var.name}-${var.env}-${var.table_name}"
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PAY_PER_REQUEST" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PAY_PER_REQUEST" ? var.read_capacity : null
  hash_key       = var.hash_key
  range_key      = var.range_key

  dynamic "server_side_encryption" {
    for_each = var.encryption == null ? [0] : [1]
    content {
      enabled = var.encryption.enabled
      kms_key_arn = var.encryption.kms_key_arn
    }
  }

  dynamic "attribute" {
    for_each = var.attributes == null ? [] : [lenth(var.attributes)]
    content {
      name = atrribute.value["name"]
      type = atrribute.value["type"]
    }
  }

  dynamic "ttl" {
    for_each = var.ttl == null ? [0] : [1]
    content {
      attribute_name = var.ttl.attribute_name
      enabled        = var.ttl.enabled
    }
  }

  dynamic global_secondary_index {
    for_each = var.global_secondary_indexes == null ? [] : [length(var.global_secondary_indexes)]
    content {
      name               = global_secondary_index.value["name"]
      hash_key           = global_secondary_index.value["hash_key"]
      range_key          = global_secondary_index.value["range_key"]
      write_capacity     = global_secondary_index.value["write_capacity"]
      read_capacity      = global_secondary_index.value["read_capacity"]
      projection_type    = global_secondary_index.value["projection_type"]
      non_key_attributes = global_secondary_index.value["non_key_attributes"]
    }
  }

  tags = {
    Name        = "${var.name}-${var.table_name}-${var.env}"
    Environment = var.env
  }
}
