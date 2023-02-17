locals {
  sources = flatten([
    for integration, resources in var.sources : [
      for resource in resources : {
        service_name = integration
        endpoint_name = resource.endpoint
        source_path = resource.source_path
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
  endpoint = each.value.endpoint_name
  source_path = each.value.source_path
  data_lake_sfn_bucket = var.data_lake_sfn_bucket
}