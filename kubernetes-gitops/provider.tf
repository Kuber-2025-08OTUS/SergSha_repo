terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.167"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.17.0"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
#   token     = var.yc_token
#   cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
#   zone      = var.yc_zone
}

provider "kubernetes" {
  # config_path = "~/.kube/config"
  host                   = yandex_kubernetes_cluster.k8s_cluster.master[0].external_v4_endpoint
  # cluster_ca_certificate = base64decode(yandex_kubernetes_cluster.k8s_cluster.master[0].cluster_ca_certificate)
  cluster_ca_certificate = yandex_kubernetes_cluster.k8s_cluster.master[0].cluster_ca_certificate
  token                  = data.yandex_client_config.client.iam_token
}

provider "helm" {
  kubernetes {
  # config_path = "~/.kube/config"
    host                   = yandex_kubernetes_cluster.k8s_cluster.master[0].external_v4_endpoint
    cluster_ca_certificate = yandex_kubernetes_cluster.k8s_cluster.master[0].cluster_ca_certificate
    token                  = data.yandex_client_config.client.iam_token
  }
}

data "yandex_client_config" "client" {}