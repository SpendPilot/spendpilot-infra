output "id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "kubelet_object_id" {
  value = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "principal_id" {
  value = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "fqdn" {
  value = azurerm_kubernetes_cluster.this.fqdn
}

output "private_fqdn" {
  value = azurerm_kubernetes_cluster.this.private_fqdn
}

output "private_dns_zone_id" {
  value = azurerm_kubernetes_cluster.this.private_dns_zone_id
}
