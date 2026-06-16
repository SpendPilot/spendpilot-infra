resource "azurerm_network_interface" "this" {
  count               = length(var.vm_names)
  name                = "${var.vm_names[count.index]}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = length(var.private_ip_addresses) > count.index ? "Static" : "Dynamic"
    private_ip_address            = length(var.private_ip_addresses) > count.index ? var.private_ip_addresses[count.index] : null
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  count                           = length(var.vm_names)
  name                            = var.vm_names[count.index]
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.this[count.index].id]
  zone                            = element(var.zones, count.index % length(var.zones))
  tags                            = var.tags

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/templates/install-docker.tftpl", {
    node_role                    = var.node_role
    postgres_enabled             = var.postgres_enabled
    postgres_image               = var.postgres_image
    postgres_db                  = var.postgres_db
    postgres_user                = var.postgres_user
    postgres_password            = var.postgres_password
    postgres_port                = var.postgres_port
    ollama_enabled               = var.ollama_enabled
    ollama_image                 = var.ollama_image
    ollama_model                 = var.ollama_model
    ollama_port                  = var.ollama_port
    bootstrap_repo_owner         = var.bootstrap_repo_owner
    bootstrap_repo_branch        = var.bootstrap_repo_branch
    bootstrap_app_env            = var.bootstrap_app_env
    bootstrap_public_base_url    = var.bootstrap_public_base_url
    bootstrap_data_vm_private_ip = var.bootstrap_data_vm_private_ip
    bootstrap_jwt_secret_key     = var.bootstrap_jwt_secret_key
  }))
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "this" {
  count                   = var.associate_with_app_gateway ? length(var.vm_names) : 0
  network_interface_id    = azurerm_network_interface.this[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.app_gateway_backend_pool_id
}
