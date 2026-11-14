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

resource "helm_release" "kyverno" {
  count = var.enable_kyverno ? 1 : 0

  name       = "kyverno"
  namespace  = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  version    = var.kyverno_chart_version

  create_namespace = true

  depends_on = [kind_cluster.default]

  # A new kind cluster is empty, so reinstall Kyverno whenever it is replaced.
  lifecycle {
    replace_triggered_by = [kind_cluster.default.id]
  }
}

resource "helm_release" "trivy_operator" {
  count = var.enable_trivy_operator ? 1 : 0

  name       = "trivy-operator"
  namespace  = "trivy-system"
  repository = "https://aquasecurity.github.io/helm-charts/"
  chart      = "trivy-operator"
  version    = var.trivy_operator_chart_version

  create_namespace = true

  # Let the node-collector (CIS node checks) run on the tainted control-plane
  # node too; without this it stays Pending there.
  values = [yamlencode({
    nodeCollector = {
      tolerations = [{
        key      = "node-role.kubernetes.io/control-plane"
        operator = "Exists"
        effect   = "NoSchedule"
      }]
    }
  })]

  depends_on = [kind_cluster.default]

  # A new kind cluster is empty, so reinstall Trivy Operator whenever it is replaced.
  lifecycle {
    replace_triggered_by = [kind_cluster.default.id]
  }
}

# Policy Reporter: a web UI for PolicyReports (Kyverno results, and Trivy
# findings via the adapter below).
resource "helm_release" "policy_reporter" {
  count = var.enable_policy_reporter ? 1 : 0

  name       = "policy-reporter"
  namespace  = "policy-reporter"
  repository = "https://kyverno.github.io/policy-reporter"
  chart      = "policy-reporter"
  version    = var.policy_reporter_chart_version

  create_namespace = true

  values = [yamlencode({
    ui = { enabled = true }
    plugin = {
      # Adds Kyverno policy details to the UI.
      kyverno = { enabled = var.enable_kyverno }
      # Adds CVE details to Trivy findings.
      trivy = { enabled = var.enable_trivy_operator }
    }
  })]

  depends_on = [kind_cluster.default]

  # A new kind cluster is empty, so reinstall Policy Reporter whenever it is replaced.
  lifecycle {
    replace_triggered_by = [kind_cluster.default.id]
  }
}

# Turns Trivy Operator reports into PolicyReports so Policy Reporter shows them.
resource "helm_release" "trivy_polr_adapter" {
  count = var.enable_policy_reporter && var.enable_trivy_operator ? 1 : 0

  name       = "trivy-operator-polr-adapter"
  namespace  = "policy-reporter"
  repository = "https://fjogeleit.github.io/trivy-operator-polr-adapter"
  chart      = "trivy-operator-polr-adapter"
  version    = var.trivy_polr_adapter_chart_version

  create_namespace = true

  # Vulnerability and config audit reports are on by default; add the rest.
  values = [yamlencode({
    adapters = {
      exposedSecretReports          = { enabled = true }
      rbacAssessmentReports         = { enabled = true }
      infraAssessmentReports        = { enabled = true }
      clusterInfraAssessmentReports = { enabled = true }
    }
  })]

  # The adapter needs Trivy's CRDs to exist first.
  depends_on = [helm_release.trivy_operator, helm_release.policy_reporter]

  lifecycle {
    replace_triggered_by = [kind_cluster.default.id]
  }
}
