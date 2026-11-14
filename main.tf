locals {

  # Host directory shared by every node. Docker Desktop on macOS only shares
  # /Users, /Volumes, /private and /tmp by default; /tmp is wiped on reboot,
  # so default to a folder inside this repo instead.
  host_storage_path = abspath(coalesce(var.host_storage_path, "${path.module}/.kind-storage"))

  node_storage_mounts = [
    {
      # Backing store for the default "standard" StorageClass (dynamic PVCs).
      host_path      = "${local.host_storage_path}/local-path"
      container_path = "/var/local-path-provisioner"
    },
    {
      # Backing store for hand-made hostPath PVs ("manual" StorageClass).
      host_path      = "${local.host_storage_path}/static"
      container_path = "/mnt/data"
    },
  ]
}

resource "kind_cluster" "default" {
  name            = var.cluster_name
  node_image      = var.node_image
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = var.api_version

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        <<-EOT
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
        EOT
        ,
        # CIS hardening (kube-bench 1.2.15-1.2.19, 1.2.30, 1.3.2, 1.4.1):
        # disable profiling, enable API server audit logging, and stop
        # extending service account token expiry.
        <<-EOT
        kind: ClusterConfiguration
        apiServer:
          extraArgs:
            profiling: "false"
            service-account-extend-token-expiration: "false"
            audit-policy-file: /etc/kubernetes/audit/audit-policy.yaml
            audit-log-path: /var/log/kubernetes/audit/audit.log
            audit-log-maxage: "30"
            audit-log-maxbackup: "10"
            audit-log-maxsize: "100"
          extraVolumes:
            - name: audit-policy
              hostPath: /etc/kubernetes/audit/audit-policy.yaml
              mountPath: /etc/kubernetes/audit/audit-policy.yaml
              readOnly: true
              pathType: File
            - name: audit-logs
              hostPath: /var/log/kubernetes/audit
              mountPath: /var/log/kubernetes/audit
              readOnly: false
              pathType: DirectoryOrCreate
        controllerManager:
          extraArgs:
            profiling: "false"
        scheduler:
          extraArgs:
            profiling: "false"
        EOT
      ]

      # Audit policy used by the API server (see ClusterConfiguration above).
      extra_mounts {
        host_path      = abspath("${path.module}/audit-policy.yaml")
        container_path = "/etc/kubernetes/audit/audit-policy.yaml"
      }

      dynamic "extra_mounts" {
        for_each = local.node_storage_mounts
        content {
          host_path      = extra_mounts.value.host_path
          container_path = extra_mounts.value.container_path
        }
      }

      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 8080
        host_port      = 8080
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 8000
        host_port      = 8000
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"

      dynamic "extra_mounts" {
        for_each = local.node_storage_mounts
        content {
          host_path      = extra_mounts.value.host_path
          container_path = extra_mounts.value.container_path
        }
      }
    }

    node {
      role = "worker"

      dynamic "extra_mounts" {
        for_each = local.node_storage_mounts
        content {
          host_path      = extra_mounts.value.host_path
          container_path = extra_mounts.value.container_path
        }
      }
    }
  }
}

