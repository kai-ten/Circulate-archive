locals {
  targets = flatten([
    for integration, resources in var.targets : [
      for resource in resources : {
        service_name = integration
        enabled = resource.enabled
        endpoint_name = resource.endpoint
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
  endpoint = each.value.endpoint_name
  data_lake_sfn_bucket = var.data_lake_sfn_bucket
  data_lake_bucket = var.data_lake_bucket
}
