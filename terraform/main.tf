locals {
  resource_name_prefix = "${var.environment}-${random_string.suffix.result}"
  common_tags          = merge(var.tags, { Environment = var.environment })
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags     = local.common_tags
}

module "network" {
  source                  = "./modules/networking"
  resource_name_prefix    = local.resource_name_prefix
  network_security_prefix = local.resource_name_prefix
  resource_group_name     = azurerm_resource_group.main.name
  resource_group_location = azurerm_resource_group.main.location
  vnet_address_space      = var.vnet_address_space
  subnet_address_prefixes = var.subnet_address_prefixes
}

module "dns" {
  source              = "./modules/dns"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_id  = module.network.virtual_network_id
}

module "acr" {
  source                  = "./modules/acr"
  resource_name_prefix    = local.resource_name_prefix
  resource_group_location = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
}

module "aks" {
  source                  = "./modules/aks"
  resource_name_prefix    = local.resource_name_prefix
  resource_group_location = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  aks_subnet_id           = module.network.eks_subnet_id
  acr_id                  = module.acr.acr_id
  database_portfolio      = module.database.database_portfolio
}

module "database" {
  source                    = "./modules/database"
  resource_name_prefix      = local.resource_name_prefix
  resource_group_location   = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  snet_db_id                = module.network.database_subnet_id
  private_dns_zone_id       = module.dns.private_dns_zone_id
  random_db_password        = module.keyvault.random_db_password
  db_admin_user             = var.db_admin_user
  dns_to_postgres_vnet_link = module.dns.dns_to_postgres_vnet_link
}

module "keyvault" {
  source                  = "./modules/keyvault"
  resource_group_location = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name

}