output "virtual_network_id" {
  description = "ID of virtual network"
  value       = azurerm_virtual_network.main.id
}

output "virtual_network_name" {
  description = "Name of virtual network"
  value       = azurerm_virtual_network.main.name
}

output "app_subnet_id" {
  description = "ID of app subnet"
  value       = azurerm_subnet.snet-app.id
}

output "eks_subnet_id" {
  description = "ID of eks subnet"
  value       = azurerm_subnet.snet-aks.id
}

output "database_subnet_id" {
  description = "ID of database subnet"
  value       = azurerm_subnet.snet-db.id
}

output "app-nsg-id" {
  description = "Id of app network security group"
  value       = azurerm_network_security_group.app-nsg.id
}

output "database-nsg-id" {
  description = "ID of database network security group"
  value       = azurerm_network_security_group.database-nsg.id
}