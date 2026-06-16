output "name" {
  value = azurerm_linux_virtual_machine_scale_set.this.name
}

output "id" {
  value = azurerm_linux_virtual_machine_scale_set.this.id
}

output "autoscale_setting_id" {
  value = azurerm_monitor_autoscale_setting.this.id
}
