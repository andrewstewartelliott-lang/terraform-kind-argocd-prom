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
  default     = true
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

variable "enable_kyverno" {
  description = "Install the Kyverno policy engine from https://kyverno.github.io/kyverno/."
  type        = bool
  default     = true
}

variable "kyverno_chart_version" {
  description = "Kyverno Helm chart version to install."
  type        = string
  default     = "3.10.0"
}

variable "enable_trivy_operator" {
  description = "Install Trivy Operator (vulnerability, misconfiguration, secret and RBAC scanning) from https://aquasecurity.github.io/helm-charts/."
  type        = bool
  default     = true
}

variable "trivy_operator_chart_version" {
  description = "Trivy Operator Helm chart version to install."
  type        = string
  default     = "0.38.1"
}

variable "enable_policy_reporter" {
  description = "Install Policy Reporter (web UI for Kyverno and Trivy results) from https://kyverno.github.io/policy-reporter. The Trivy adapter is also installed when enable_trivy_operator is true."
  type        = bool
  default     = true
}

variable "policy_reporter_chart_version" {
  description = "Policy Reporter Helm chart version to install."
  type        = string
  default     = "3.11.2"
}

variable "trivy_polr_adapter_chart_version" {
  description = "trivy-operator-polr-adapter Helm chart version to install."
  type        = string
  default     = "0.11.5"
}
