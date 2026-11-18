output "private_dns_zone_id"{
  description = "ID of Private DNS zone"
  value = azurerm_private_dns_zone.postgres.id
}

output "dns_to_postgres_vnet_link" {
  description = "Link"
  value       = azurerm_private_dns_zone_virtual_network_link.dns_link.id
}