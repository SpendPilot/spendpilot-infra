module "resource_group" {
  source = "./modules/resource-group"

  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

module "log_analytics" {
  source = "./modules/log-analytics"

  name                = "${local.name}-law"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

module "edge_network" {
  source = "./modules/network"

  name                = "${local.name}-hub-vnet"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  address_space       = [var.edge_vnet_cidr]
  tags                = local.tags

  subnets = {
    "appgw-subnet" = {
      address_prefixes = [var.appgw_subnet_cidr]
    }
    "AzureBastionSubnet" = {
      address_prefixes = [var.bastion_subnet_cidr]
    }
    "AzureFirewallSubnet" = {
      address_prefixes = [var.firewall_subnet_cidr]
    }
  }
}

module "app_network" {
  source = "./modules/network"

  name                = "${local.name}-app-spoke-vnet"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  address_space       = [var.app_vnet_cidr]
  tags                = local.tags

  subnets = {
    "frontend-subnet" = {
      address_prefixes = [var.frontend_subnet_cidr]
    }
    "backend-subnet" = {
      address_prefixes = [var.backend_subnet_cidr]
    }
    "static-app-subnet" = {
      address_prefixes = [var.static_app_subnet_cidr]
    }
  }
}

module "data_network" {
  source = "./modules/network"

  name                = "${local.name}-data-spoke-vnet"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  address_space       = [var.data_vnet_cidr]
  tags                = local.tags

  subnets = {
    "data-ai-subnet" = {
      address_prefixes = [var.data_ai_subnet_cidr]
    }
    "postgres-subnet" = {
      address_prefixes   = [var.postgres_subnet_cidr]
      delegation_service = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }
}

resource "azurerm_virtual_network_peering" "edge_to_app" {
  name                         = "${local.name}-hub-to-app"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.edge_network.virtual_network_name
  remote_virtual_network_id    = module.app_network.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "app_to_edge" {
  name                         = "${local.name}-app-to-hub"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.app_network.virtual_network_name
  remote_virtual_network_id    = module.edge_network.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "edge_to_data" {
  name                         = "${local.name}-hub-to-data"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.edge_network.virtual_network_name
  remote_virtual_network_id    = module.data_network.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "data_to_edge" {
  name                         = "${local.name}-data-to-hub"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.data_network.virtual_network_name
  remote_virtual_network_id    = module.edge_network.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "app_to_data" {
  name                         = "${local.name}-app-to-data"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.app_network.virtual_network_name
  remote_virtual_network_id    = module.data_network.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "data_to_app" {
  name                         = "${local.name}-data-to-app"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.data_network.virtual_network_name
  remote_virtual_network_id    = module.app_network.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_public_ip" "firewall" {
  name                = "${local.name}-fw-pip"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_firewall" "hub" {
  name                = "${local.name}-hub-fw"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  threat_intel_mode   = "Alert"
  tags                = local.tags

  ip_configuration {
    name                 = "hub-configuration"
    subnet_id            = module.edge_network.subnet_ids["AzureFirewallSubnet"]
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_firewall_application_rule_collection" "egress" {
  name                = "${local.name}-allow-web-egress"
  azure_firewall_name = azurerm_firewall.hub.name
  resource_group_name = module.resource_group.name
  priority            = 100
  action              = "Allow"

  rule {
    name             = "allow-http-https-outbound"
    source_addresses = [var.app_vnet_cidr, var.data_vnet_cidr]
    target_fqdns     = ["*"]

    protocol {
      port = 80
      type = "Http"
    }

    protocol {
      port = 443
      type = "Https"
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "spoke_private" {
  name                = "${local.name}-allow-private-app-data"
  azure_firewall_name = azurerm_firewall.hub.name
  resource_group_name = module.resource_group.name
  priority            = 200
  action              = "Allow"

  rule {
    name                  = "allow-backend-to-postgres"
    source_addresses      = [var.backend_subnet_cidr]
    destination_addresses = [var.postgres_subnet_cidr]
    destination_ports     = ["5432"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "allow-backend-to-ollama"
    source_addresses      = [var.backend_subnet_cidr]
    destination_addresses = [var.data_ai_subnet_cidr]
    destination_ports     = [tostring(var.ollama_port)]
    protocols             = ["TCP"]
  }
}

resource "azurerm_route_table" "app_spoke" {
  name                = "${local.name}-app-spoke-rt"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = local.tags

  route {
    name                   = "internet-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_route_table" "data_spoke" {
  name                = "${local.name}-data-spoke-rt"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = local.tags

  route {
    name                   = "internet-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "frontend" {
  subnet_id      = module.app_network.subnet_ids["frontend-subnet"]
  route_table_id = azurerm_route_table.app_spoke.id
}

resource "azurerm_subnet_route_table_association" "backend" {
  subnet_id      = module.app_network.subnet_ids["backend-subnet"]
  route_table_id = azurerm_route_table.app_spoke.id
}

resource "azurerm_subnet_route_table_association" "static_app" {
  subnet_id      = module.app_network.subnet_ids["static-app-subnet"]
  route_table_id = azurerm_route_table.app_spoke.id
}

resource "azurerm_subnet_route_table_association" "data_ai" {
  subnet_id      = module.data_network.subnet_ids["data-ai-subnet"]
  route_table_id = azurerm_route_table.data_spoke.id
}

module "frontend_subnet_nsg" {
  source = "./modules/subnet-nsg"

  name                = "${local.name}-frontend-nsg"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.app_network.subnet_ids["frontend-subnet"]
  tags                = local.tags

  rules = concat(
    [
      {
        name                       = "allow-appgw-to-frontend"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3000"
        source_address_prefix      = var.appgw_subnet_cidr
        destination_address_prefix = "*"
      },
      {
        name                       = "allow-bastion-to-frontend-ssh"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = var.bastion_subnet_cidr
        destination_address_prefix = "*"
      }
    ],
    length(var.admin_allowed_cidrs) == 0 ? [] : [
      {
        name                       = "allow-ssh-admin"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefixes    = var.admin_allowed_cidrs
        destination_address_prefix = "*"
      }
    ],
  )
}

module "backend_subnet_nsg" {
  source = "./modules/subnet-nsg"

  name                = "${local.name}-backend-nsg"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.app_network.subnet_ids["backend-subnet"]
  tags                = local.tags

  rules = concat(
    [
      {
        name                       = "allow-appgw-to-api"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8000"
        source_address_prefix      = var.appgw_subnet_cidr
        destination_address_prefix = "*"
      },
      {
        name                       = "allow-bastion-to-backend-ssh"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = var.bastion_subnet_cidr
        destination_address_prefix = "*"
      }
    ],
    length(var.admin_allowed_cidrs) == 0 ? [] : [
      {
        name                       = "allow-ssh-admin"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefixes    = var.admin_allowed_cidrs
        destination_address_prefix = "*"
      }
    ],
  )
}

module "static_app_subnet_nsg" {
  source = "./modules/subnet-nsg"

  name                = "${local.name}-static-app-nsg"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.app_network.subnet_ids["static-app-subnet"]
  tags                = local.tags

  rules = concat(
    [
      {
        name                       = "allow-appgw-to-static-app"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = var.appgw_subnet_cidr
        destination_address_prefix = "*"
      },
      {
        name                       = "allow-bastion-to-static-app-ssh"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = var.bastion_subnet_cidr
        destination_address_prefix = "*"
      }
    ],
    length(var.admin_allowed_cidrs) == 0 ? [] : [
      {
        name                       = "allow-ssh-admin"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefixes    = var.admin_allowed_cidrs
        destination_address_prefix = "*"
      }
    ],
  )
}

module "data_ai_subnet_nsg" {
  source = "./modules/subnet-nsg"

  name                = "${local.name}-data-ai-nsg"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.data_network.subnet_ids["data-ai-subnet"]
  tags                = local.tags

  rules = concat(
    [
      {
        name                       = "allow-backend-to-ollama"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = tostring(var.ollama_port)
        source_address_prefix      = var.backend_subnet_cidr
        destination_address_prefix = "*"
      },
      {
        name                       = "allow-bastion-to-data-ai-ssh"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = var.bastion_subnet_cidr
        destination_address_prefix = "*"
      }
    ],
    length(var.admin_allowed_cidrs) == 0 ? [] : [
      {
        name                       = "allow-ssh-admin"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefixes    = var.admin_allowed_cidrs
        destination_address_prefix = "*"
      }
    ],
  )
}

module "app_gateway" {
  source = "./modules/app-gateway-vm-edge"

  name                = "${local.name}-appgw"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.edge_network.subnet_ids["appgw-subnet"]
  min_capacity        = var.app_gateway_min_capacity
  max_capacity        = var.app_gateway_max_capacity
  primary_host_name   = var.primary_host_name
  static_host_name    = var.static_app_host_name
  tags                = local.tags
}

module "postgres" {
  source = "./modules/postgres-flex"

  name                   = local.postgres_server_name
  resource_group_name    = module.resource_group.name
  location               = module.resource_group.location
  server_version         = var.postgres_version
  delegated_subnet_id    = module.data_network.subnet_ids["postgres-subnet"]
  virtual_network_ids    = [module.data_network.virtual_network_id, module.app_network.virtual_network_id]
  private_dns_zone_name  = local.postgres_private_dns_zone
  administrator_login    = var.postgres_app_username
  administrator_password = var.postgres_app_password
  storage_mb             = var.postgres_storage_mb
  sku_name               = var.postgres_sku_name
  backup_retention_days  = var.postgres_backup_retention_days
  zone                   = var.postgres_zone
  ha_mode                = var.postgres_ha_mode
  ha_standby_zone        = var.postgres_ha_standby_zone
  database_name          = var.postgres_database_name
  tags                   = local.tags
}

resource "azurerm_lb" "ollama_private" {
  name                = "${local.name}-ollama-ilb"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = "Standard"
  tags                = local.tags

  frontend_ip_configuration {
    name                          = "private-frontend"
    subnet_id                     = module.data_network.subnet_ids["data-ai-subnet"]
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ollama_lb_private_ip
  }
}

resource "azurerm_lb_backend_address_pool" "ollama_private" {
  name            = "ollama-backend-pool"
  loadbalancer_id = azurerm_lb.ollama_private.id
}

resource "azurerm_lb_probe" "ollama_private" {
  name            = "ollama-tcp-probe"
  loadbalancer_id = azurerm_lb.ollama_private.id
  protocol        = "Tcp"
  port            = var.ollama_port
}

resource "azurerm_lb_rule" "ollama_private" {
  name                           = "ollama-rule"
  loadbalancer_id                = azurerm_lb.ollama_private.id
  protocol                       = "Tcp"
  frontend_port                  = var.ollama_port
  backend_port                   = var.ollama_port
  frontend_ip_configuration_name = "private-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ollama_private.id]
  probe_id                       = azurerm_lb_probe.ollama_private.id
}

module "frontend_vmss" {
  source = "./modules/linux-vmss-group"

  name                                 = local.frontend_scale_set_name
  resource_group_name                  = module.resource_group.name
  location                             = module.resource_group.location
  subnet_id                            = module.app_network.subnet_ids["frontend-subnet"]
  vm_size                              = var.frontend_vm_size
  min_instances                        = var.frontend_vmss_min_instances
  max_instances                        = var.frontend_vmss_max_instances
  admin_username                       = var.admin_username
  admin_password                       = var.admin_password
  zones                                = var.zones
  node_role                            = "frontend"
  bootstrap_repo_owner                 = var.bootstrap_repo_owner
  bootstrap_repo_branch                = var.bootstrap_repo_branch
  bootstrap_app_env                    = "development"
  bootstrap_public_api_base_url        = local.frontend_public_api_base_url
  bootstrap_public_base_url            = "http://${var.primary_host_name}"
  bootstrap_jwt_secret_key             = var.jwt_secret_key
  application_gateway_backend_pool_ids = [module.app_gateway.backend_pool_ids.frontend]
  tags                                 = local.tags
}

module "backend_vmss" {
  source = "./modules/linux-vmss-group"

  name                                 = local.backend_scale_set_name
  resource_group_name                  = module.resource_group.name
  location                             = module.resource_group.location
  subnet_id                            = module.app_network.subnet_ids["backend-subnet"]
  vm_size                              = var.backend_vm_size
  min_instances                        = var.backend_vmss_min_instances
  max_instances                        = var.backend_vmss_max_instances
  admin_username                       = var.admin_username
  admin_password                       = var.admin_password
  zones                                = var.zones
  node_role                            = "backend"
  bootstrap_repo_owner                 = var.bootstrap_repo_owner
  bootstrap_repo_branch                = var.bootstrap_repo_branch
  bootstrap_app_env                    = var.environment == "prod" ? "production" : var.environment
  bootstrap_public_base_url            = "http://${var.primary_host_name}"
  bootstrap_database_url               = local.backend_database_url
  bootstrap_database_host              = local.backend_database_host
  bootstrap_database_port              = 5432
  bootstrap_ollama_base_url            = local.ollama_private_base_url
  bootstrap_jwt_secret_key             = var.jwt_secret_key
  bootstrap_expense_service_url        = "http://expense-service:8001"
  bootstrap_ai_service_url             = "http://ai-service:8002"
  bootstrap_receipt_threshold          = 75
  bootstrap_upload_dir                 = "/data/uploads"
  bootstrap_ollama_timeout             = 30
  application_gateway_backend_pool_ids = [module.app_gateway.backend_pool_ids.api]
  tags                                 = local.tags
}

module "static_app_vm" {
  source = "./modules/static-nginx-vm"

  name                        = local.static_app_vm_name
  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  subnet_id                   = module.app_network.subnet_ids["static-app-subnet"]
  vm_size                     = var.static_app_vm_size
  admin_username              = var.admin_username
  admin_password              = var.admin_password
  zone                        = element(var.zones, 0)
  host_name                   = var.static_app_host_name
  html_content                = local.static_app_html
  app_gateway_backend_pool_id = module.app_gateway.backend_pool_ids.static
  tags                        = local.tags
}

module "data_ai_vmss" {
  source = "./modules/linux-vmss-group"

  name                                   = local.data_ai_scale_set_name
  resource_group_name                    = module.resource_group.name
  location                               = module.resource_group.location
  subnet_id                              = module.data_network.subnet_ids["data-ai-subnet"]
  vm_size                                = var.data_vm_size
  min_instances                          = var.data_ai_vmss_min_instances
  max_instances                          = var.data_ai_vmss_max_instances
  admin_username                         = var.admin_username
  admin_password                         = var.admin_password
  zones                                  = var.zones
  node_role                              = "data-ai"
  ollama_enabled                         = true
  ollama_image                           = var.ollama_container_image
  ollama_model                           = var.ollama_model
  ollama_port                            = var.ollama_port
  bootstrap_repo_owner                   = var.bootstrap_repo_owner
  bootstrap_repo_branch                  = var.bootstrap_repo_branch
  bootstrap_app_env                      = var.environment == "prod" ? "production" : var.environment
  bootstrap_public_base_url              = "http://${var.primary_host_name}"
  bootstrap_jwt_secret_key               = var.jwt_secret_key
  load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.ollama_private.id]
  tags                                   = local.tags
}
