output "acr_id" {
  description = "Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_login_server" {
  description = "ACR login server"
  value = azurerm_container_registry.acr.login_server
}