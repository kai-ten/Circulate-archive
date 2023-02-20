locals {
  sources = flatten([
    for integration, resources in var.sources : [
      for resource in resources : {
        service_name = integration
        enabled = resource.enabled
        endpoint_name = resource.endpoint
        src_path = resource.src_path
      }
    ]
  ])
}

module "source_lambda" {
  for_each = {
    for idx, val in local.sources: idx => val
  }
  source          = "./module"

  name = var.name
  env = var.env
  service = each.value.service_name
  enabled = each.value.enabled
  endpoint = each.value.endpoint_name
  src_path = each.value.src_path
  data_lake_sfn_bucket = var.data_lake_sfn_bucket
}
