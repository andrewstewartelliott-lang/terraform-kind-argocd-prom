data "http" "argo_base_manifest" {
  url = "https://raw.githubusercontent.com/andrewstewartelliott-lang/argocd/main/argo/base/base.yaml"
}

data "http" "k8s_viewer_cluster_role_manifest" {
  url = "https://raw.githubusercontent.com/andrewstewartelliott-lang/argocd/main/argo/applications/k8s-viewer/clusterRole.yaml"
}

resource "null_resource" "apply_argo_base" {
  triggers = {
    manifest_sha = sha256(data.http.argo_base_manifest.response_body)
    cluster_id   = kind_cluster.default.id
    release_id   = helm_release.argocd.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${kind_cluster.default.kubeconfig_path}
      cat <<'YAML' | kubectl apply -f -
      ${data.http.argo_base_manifest.response_body}
      YAML
    EOT
  }

  depends_on = [kind_cluster.default, helm_release.argocd]
}

resource "null_resource" "apply_k8s_viewer_cluster_role" {
  triggers = {
    manifest_sha = sha256(data.http.k8s_viewer_cluster_role_manifest.response_body)
    cluster_id   = kind_cluster.default.id
    release_id   = helm_release.argocd.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${kind_cluster.default.kubeconfig_path}
      cat <<'YAML' | kubectl apply -f -
      ${data.http.k8s_viewer_cluster_role_manifest.response_body}
      YAML
    EOT
  }

  depends_on = [kind_cluster.default, helm_release.argocd]
}