output "kind_cluster_status" {
  description = "Whether the kind cluster has completed provisioning and is ready"
  value       = kind_cluster.default.completed ? "ready" : "not_ready"
}

output "argocd_helm_message" {
  description = "The notes returned by the Argo CD Helm release"
  value       = var.enable_argo ? helm_release.argocd[0].metadata.notes : "Argo CD is disabled (enable_argo = false)"
}
