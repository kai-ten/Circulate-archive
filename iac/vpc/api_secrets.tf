resource "aws_secretsmanager_secret" "circulate_api" {
  name = "/${var.name}-${var.env}/api/variables"
}

# This secret contains the currently supported API integrations
resource "aws_secretsmanager_secret_version" "circulate_api_version" {
  secret_id     = aws_secretsmanager_secret.circulate_api.id
  secret_string = <<EOF
   {
    "okta_url": "",
    "okta_api_key": ""
   }
EOF
}