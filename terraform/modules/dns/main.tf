/*
 * DNS Module
 * This module creates the private DNS zone for PostgreSQL Flexible Server
 * and links it to the VNet for private name resolution.
 */

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                = "db-dns-link"
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id
  virtual_network_id  = var.virtual_network_id
}