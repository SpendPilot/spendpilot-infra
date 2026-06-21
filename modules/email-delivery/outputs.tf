output "service_bus_namespace_id" {
  value = azurerm_servicebus_namespace.this.id
}

output "service_bus_namespace_name" {
  value = azurerm_servicebus_namespace.this.name
}

output "service_bus_fully_qualified_namespace" {
  value = "${azurerm_servicebus_namespace.this.name}.servicebus.windows.net"
}

output "service_bus_queue_name" {
  value = azurerm_servicebus_queue.email_requests.name
}

output "function_app_name" {
  value = azurerm_linux_function_app.this.name
}

output "function_app_id" {
  value = azurerm_linux_function_app.this.id
}

output "function_app_default_hostname" {
  value = azurerm_linux_function_app.this.default_hostname
}

output "function_app_principal_id" {
  value = azurerm_linux_function_app.this.identity[0].principal_id
}

output "communication_service_id" {
  value = azurerm_communication_service.this.id
}

output "communication_service_endpoint" {
  value = "https://${azurerm_communication_service.this.hostname}"
}

output "email_service_id" {
  value = azurerm_email_communication_service.this.id
}

output "email_domain_id" {
  value = azurerm_email_communication_service_domain.this.id
}

output "email_domain_from_sender_domain" {
  value = azurerm_email_communication_service_domain.this.from_sender_domain
}

output "email_sender_address" {
  value = local.sender_address
}

output "email_domain_verification_records" {
  value = try(azurerm_email_communication_service_domain.this.verification_records, [])
}
