terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "5.13.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35" # Or ">= 2.0.0" depending on your version constraints
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "kubernetes" {
  host                   = module.aks.kubernetes_cluster_host
  client_certificate     = base64decode(module.aks.kubernetes_cluster_certificate)
  client_key             = base64decode(module.aks.kubernetes_cluster_client_key)
  cluster_ca_certificate = base64decode(module.aks.kubernetes_cluster_ca_certificate)
}
