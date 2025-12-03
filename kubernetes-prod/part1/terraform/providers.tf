terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.170"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
#   token     = var.yc_token
#   cloud_id  = var.yc_cloud_id
  folder_id = var.yc.folder.id
#   zone      = var.yc_zone
}
