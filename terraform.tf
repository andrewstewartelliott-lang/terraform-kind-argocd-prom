terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.0.19"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "kubernetes" {
  host                   = kind_cluster.default.endpoint
  cluster_ca_certificate = base64decode(kind_cluster.default.cluster_ca_certificate)
  client_certificate     = base64decode(kind_cluster.default.client_certificate)
  client_key             = base64decode(kind_cluster.default.client_key)
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.default.endpoint
    cluster_ca_certificate = base64decode(kind_cluster.default.cluster_ca_certificate)
    client_certificate     = base64decode(kind_cluster.default.client_certificate)
    client_key             = base64decode(kind_cluster.default.client_key)
  }
}