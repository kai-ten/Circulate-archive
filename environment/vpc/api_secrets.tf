# Contains all potential parameters that will be used by the integrations

resource "aws_secretsmanager_secret" "circulate_postgresdb" {
  name = "/${var.name}-${var.env}/postgres/credentials"
}

resource "aws_secretsmanager_secret" "circulate_okta_api" {
  name = "/${var.name}-${var.env}/okta/credentials"
}

# This secret contains the currently supported API integrations
resource "aws_secretsmanager_secret_version" "circulate_okta_api_version" {
  secret_id     = aws_secretsmanager_secret.circulate_okta_api.id
  secret_string = <<EOF
   {
    "okta_domain": "",
    "okta_api_key": ""
   }
EOF
}