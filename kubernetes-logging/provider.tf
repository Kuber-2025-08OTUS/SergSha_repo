terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.95"
    }
    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = "~> 2.23"
    # }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
#   token     = var.yc_token
#   cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
#   zone      = var.yc_zone
}

# provider "kubernetes" {
#   config_path = "~/.kube/config"  # или путь к вашему kubeconfig
# }
