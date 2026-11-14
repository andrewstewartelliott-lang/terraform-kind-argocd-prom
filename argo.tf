data "http" "argo_base_manifest" {
  count = var.enable_argo ? 1 : 0

  url = var.argo_manifest_url
}

resource "null_resource" "apply_argo_base" {
  count = var.enable_argo ? 1 : 0

  triggers = {
    manifest_sha = sha256(data.http.argo_base_manifest[0].response_body)
    cluster_id   = kind_cluster.default.id
    release_id   = helm_release.argocd[0].id
  }

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${kind_cluster.default.kubeconfig_path}
      cat <<'YAML' | kubectl apply -f -
      ${data.http.argo_base_manifest[0].response_body}
      YAML
    EOT
  }

  depends_on = [kind_cluster.default, helm_release.argocd]
}

# null_resource.apply_argo_base gained a count; keep the existing instance
# instead of re-applying it.
moved {
  from = null_resource.apply_argo_base
  to   = null_resource.apply_argo_base[0]
}
