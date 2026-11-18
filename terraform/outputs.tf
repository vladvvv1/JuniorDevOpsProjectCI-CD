output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "virtual_network_id" {
  description = "ID of virtual network"
  value       = module.network.virtual_network_id
}

output "virtual_network_name" {
  description = "Name of virtual network name"
  value       = module.network.virtual_network_name
}

output "app_subnet_id" {
  description = "ID of app subnet"
  value       = module.network.app_subnet_id
}

output "database_subnet_id" {
  description = "ID of database subnet"
  value       = module.network.database_subnet_id
}

output "app-nsg-id" {
  description = "Id of app network security group"
  value       = module.network.app-nsg-id
}

output "database-nsg-id" {
  description = "ID of database network security group"
  value       = module.network.database-nsg-id
}

output "private_dns_zone_id" {
  description = "The name of the private DNS zone"
  value       = module.dns.private_dns_zone_id
}

output "acr_id" {
  description = "Azure Container Registry"
  value       = module.acr.acr_id
}