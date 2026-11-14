resource "helm_release" "argocd" {
  count = var.enable_argo ? 1 : 0

  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "10.18.0"

  create_namespace = true

  set = [
    {
      name  = "controller.metrics.enabled"
      value = "true"
    },
    {
      name  = "redis.exporter.enabled"
      value = "true"
    },
    {
      name  = "redis.metrics.enabled"
      value = "true"
    },
    {
      name  = "server.metrics.enabled"
      value = "true"
    },
  ]

  depends_on = [kind_cluster.default]

  # A new kind cluster is empty, so reinstall Argo CD whenever it is replaced.
  lifecycle {
    replace_triggered_by = [kind_cluster.default.id]
  }
}

# helm_release.argocd gained a count; keep the existing release instead of
# reinstalling it.
moved {
  from = helm_release.argocd
  to   = helm_release.argocd[0]
}

resource "helm_release" "kro" {
  count = var.enable_kro ? 1 : 0

  name      = "kro"
  namespace = "kro-system"
  chart     = "oci://registry.k8s.io/kro/charts/kro"
  version   = var.kro_chart_version

  create_namespace = true

  depends_on = [kind_cluster.default]

  # A new kind cluster is empty, so reinstall kro whenever it is replaced.
  lifecycle {
    replace_triggered_by = [kind_cluster.default.id]
  }
}
