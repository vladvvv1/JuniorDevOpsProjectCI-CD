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
  source = "./modules/networking"

  resource_name_prefix    = local.resource_name_prefix
  network_security_prefix = local.resource_name_prefix
  resource_group_name     = azurerm_resource_group.main.name
  resource_group_location = azurerm_resource_group.main.location
  vnet_address_space      = var.vnet_address_space
  subnet_address_prefixes = var.subnet_address_prefixes
}

module "dns" {
  source = "./modules/dns"

  resource_group_name = azurerm_resource_group.main.name
  virtual_network_id  = module.network.virtual_network_id
}

module "acr" {
  source = "./modules/acr"

  resource_name_prefix    = local.resource_name_prefix
  resource_group_location = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
}

module "aks" {
  source = "./modules/aks"

  resource_name_prefix    = local.resource_name_prefix
  resource_group_location = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  aks_subnet_id           = module.network.eks_subnet_id
  acr_id                  = module.acr.acr_id
  # postgres_fqdn = module.database.postgres_fqdn
  # acr_login_server = module.acr.acr_login_server
  # db_admin_user = var.db_admin_user
  # database_portfolio_name = module.database.database_portfolio_name
  # administrator_password = var.db_admin_password
  database_portfolio = module.database.database_portfolio
}

module "database" {
  source = "./modules/database"

  resource_name_prefix      = local.resource_name_prefix
  resource_group_location   = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  snet_db_id                = module.network.database_subnet_id
  private_dns_zone_id       = module.dns.private_dns_zone_id
  db_admin_password         = var.db_admin_password
  db_admin_user             = var.db_admin_user
  dns_to_postgres_vnet_link = module.dns.dns_to_postgres_vnet_link
}

# resource "kubernetes_job" "db_migration" {
#   metadata {
#     name      = "portfolio-db-migration"
#     namespace = "default"
#   }

#   spec {
#     backoff_limit = 4 

#     template {
#       metadata {
#         name = "db-migration-pod"
#       }
#       spec {
#         container {
#           name  = "migration-container"

#           image = "${module.acr.acr_login_server}/db-migration:v5" 

#           command = ["/bin/sh", "-c"]
#           args    = [
#             "PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f 01-init.sql && PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f 02-import.sql"
#           ]
#           env {
#             name  = "DB_HOST"
#             value = module.database.postgres_fqdn
#           }
#           env {
#             name  = "DB_USER"
#             value = var.db_admin_user
#           }
#           env {
#             name  = "DB_PASSWORD"
#             value = var.db_admin_password
#           }
#           env {
#             name  = "DB_NAME"
#             value = module.database.database_portfolio_name
#           }
#         }

#         restart_policy = "OnFailure"
#       }
#     }
#   }

#   # Це гарантує правильний порядок створення інфраструктури
#   depends_on = [
#     module.aks.kuber_cluster_id,
#     module.aks,
#     module.database.database_portfolio
#   ]
# }
