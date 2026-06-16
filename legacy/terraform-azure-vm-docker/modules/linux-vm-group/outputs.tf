output "vm_names" {
  value = [for vm in azurerm_linux_virtual_machine.this : vm.name]
}

output "vm_ids" {
  value = [for vm in azurerm_linux_virtual_machine.this : vm.id]
}

output "nic_ids" {
  value = [for nic in azurerm_network_interface.this : nic.id]
}

output "private_ip_addresses" {
  value = [for nic in azurerm_network_interface.this : nic.private_ip_address]
}
