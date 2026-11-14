resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  create_namespace = true

  set {
    name  = "redis.exporter.enabled"
    value = "true"
  }

  set {
    name  = "redis.metrics.enabled"
    value = "true"
  }

  set {
    name  = "server.metrics.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  depends_on = [kind_cluster.default]

  # A new kind cluster is empty, so reinstall Argo CD whenever it is replaced.
  lifecycle {
    replace_triggered_by = [kind_cluster.default.id]
  }
}
