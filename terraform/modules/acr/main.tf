resource "azurerm_container_registry" "acr" {
  name                = "acr${replace(var.resource_name_prefix, "-", "")}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  sku                 = "Basic"
  admin_enabled       = false
}

