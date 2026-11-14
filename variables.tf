variable "cluster_name" {
  description = "The name of the kind cluster"
  type        = string
  default     = "test-cluster"
}

variable "api_version" {
  description = "The API version for the kind cluster"
  type        = string
  default     = "kind.x-k8s.io/v1alpha4"
}

variable "node_image" {
  description = "The node image for the kind cluster"
  type        = string
  default     = "kindest/node:v1.36.1"
}

variable "argo_manifest_url" {
  description = "The URL for the ArgoCD base manifest"
  type        = string
  default     = "https://raw.githubusercontent.com/andrewstewartelliott-lang/argocd/refs/heads/main/argo/base/base.yaml"
}
variable "host_storage_path" {
  description = "Host directory mounted into every kind node for PV data. Defaults to ./.kind-storage in this repo."
  type        = string
  default     = ""
}

variable "enable_argo" {
  description = "Install Argo CD (helm.tf) and apply the Argo base manifest (argo.tf). Set to false for a bare kind cluster."
  type        = bool
  default     = false
}

variable "enable_kro" {
  description = "Install kro (Kube Resource Orchestrator) from oci://registry.k8s.io/kro/charts/kro."
  type        = bool
  default     = true
}

variable "kro_chart_version" {
  description = "kro Helm chart version to install."
  type        = string
  default     = "0.10.0"
}
