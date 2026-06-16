output "id" {
  value = azurerm_application_gateway.this.id
}

output "name" {
  value = azurerm_application_gateway.this.name
}

output "public_ip_address" {
  value = azurerm_public_ip.this.ip_address
}

output "backend_pool_ids" {
  value = {
    frontend = one([
      for pool in azurerm_application_gateway.this.backend_address_pool : pool.id
      if pool.name == "frontend-pool"
    ])
    api = one([
      for pool in azurerm_application_gateway.this.backend_address_pool : pool.id
      if pool.name == "api-pool"
    ])
    static = one([
      for pool in azurerm_application_gateway.this.backend_address_pool : pool.id
      if pool.name == "static-pool"
    ])
  }
}
