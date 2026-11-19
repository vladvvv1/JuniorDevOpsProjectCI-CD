/*
 * Database Module
 * This module creates a PostgreSQL Flexible Server  
*/

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                          = "${var.resource_name_prefix}-pg"
  resource_group_name           = var.resource_group_name
  location                      = var.resource_group_location
  version                       = "14"
  public_network_access_enabled = false

  delegated_subnet_id = var.snet_db_id
  private_dns_zone_id = var.private_dns_zone_id

  administrator_login    = var.db_admin_user
  administrator_password = var.db_admin_password

  storage_mb = 32768
  sku_name   = "B_Standard_B1ms"
  zone       = "1"

  depends_on = [var.dns_to_postgres_vnet_link]
}

resource "azurerm_postgresql_flexible_server_database" "portfolio" {
  name      = "portfolio"
  server_id = azurerm_postgresql_flexible_server.postgres.id

  charset   = "UTF8"
  collation = "en_US.utf8"
}