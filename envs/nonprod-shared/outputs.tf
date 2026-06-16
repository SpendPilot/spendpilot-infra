output "resource_group_name" {
  value = module.resource_group.name
}

output "dev_origin_contract" {
  value = local.dev_origin_contract
}

output "staging_origin_contract" {
  value = local.staging_origin_contract
}

output "origin_contracts" {
  value = {
    dev     = local.dev_origin_contract
    staging = local.staging_origin_contract
  }
}
