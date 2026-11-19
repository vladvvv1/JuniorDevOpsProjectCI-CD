resource "azurerm_virtual_network" "main" {
  name                = var.virtual_network_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_address_space]
}

resource "azurerm_subnet" "snet-app" {
  name                 = "snet-app"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name

  address_prefixes = [var.subnet_address_prefixes[0]]

  delegation {
    name = "delegation-app-subnet"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "snet-aks" {
  name                 = "snet-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefixes[1]]
}

resource "azurerm_subnet" "snet-db" {
  name                 = "snet-db"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefixes[2]]

  delegation {
    name = "delegation-postgres"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_network_security_group" "app-nsg" {
  name                = "${var.resource_name_prefix}-public-nsg"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location

  security_rule {
    name                       = "allow_http_inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_https_inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "database-nsg" {
  name                = "${var.resource_name_prefix}-database-nsg"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location

  security_rule {
    name                       = "database_nsg_rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.subnet_address_prefixes[1] # snet-aks
    destination_address_prefix = var.subnet_address_prefixes[2] # snet-db
  }
}

# Асоціація для snet-app
resource "azurerm_subnet_network_security_group_association" "app-association" {
  subnet_id                 = azurerm_subnet.snet-app.id
  network_security_group_id = azurerm_network_security_group.app-nsg.id
}

# ДОДАНО: Асоціація публічної NSG з підмережею AKS
resource "azurerm_subnet_network_security_group_association" "aks-association" {
  subnet_id                 = azurerm_subnet.snet-aks.id
  network_security_group_id = azurerm_network_security_group.app-nsg.id
}

# Асоціація для snet-db
resource "azurerm_subnet_network_security_group_association" "database-association" {
  subnet_id                 = azurerm_subnet.snet-db.id
  network_security_group_id = azurerm_network_security_group.database-nsg.id
}