output "kuber_cluster_id" {
  description = "Kubernetes cluster id"
  value = azurerm_kubernetes_cluster.aks.id
}

output "role_assignment_aks_acr_pull" {
  description = "Azurerm role assignment aks acr pull"
  value = azurerm_role_assignment.aks_acr_pull.id
}

output "kubernetes_cluster_host" {
  description = "Kubernetes cluster AKS kube config host"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "kubernetes_cluster_certificate" {
  description = "Kubernetes cluster AKS kube config client certificate"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  sensitive   = true
}

output "kubernetes_cluster_client_key" {
  description = "Kubernetes cluster AKS kube config client key"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  sensitive   = true
}

output "kubernetes_cluster_ca_certificate" {
  description = "Kubernetes cluster AKS kube config cluster CA certificate"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  sensitive   = true
}
