resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.resource_name_prefix}-aks"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.resource_name_prefix}-aks"

  node_provisioning_profile {
    mode = "Auto"
  }

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "standard_b2s_v2"
    vnet_subnet_id = var.aks_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure" # Use "kubenet" if you are not using Azure CNI
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"

    # Include pod_cidr ONLY if network_plugin is "kubenet" or network_plugin_mode is "overlay"
    # pod_cidr     = "172.17.0.0/16"
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}

