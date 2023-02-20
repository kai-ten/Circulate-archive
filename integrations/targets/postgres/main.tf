locals {
  targets = flatten([
    for integration, resources in var.targets : [
      for resource in resources : {
        service_name = integration
        enabled = resource.enabled
        endpoint_name = resource.endpoint
        src_path = resource.src_path
      }
    ]
  ])
}

module "target_lambda" {
  for_each = {
    for idx, val in local.targets: idx => val
  }
  source          = "./module"

  name = var.name
  env = var.env
  service = each.value.service_name
  enabled = each.value.enabled
  src_path = each.value.src_path
  endpoint = each.value.endpoint_name
  data_lake_sfn_bucket = var.data_lake_sfn_bucket
  integration_security_group_id = var.integration_security_group_id
  vpc_private_subnets = var.vpc_private_subnets
  database_secret_name = var.database_secret_name
}
