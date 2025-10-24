# variable "yc_token" {
#   type        = string
#   description = "Yandex Cloud OAuth token"
#   sensitive   = true
# }

variable "yc_cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
}

variable "yc_folder_id" {
  type        = string
  description = "Yandex Cloud Folder ID"
}

variable "yc_folder" {
  type        = string
  description = "Yandex Cloud Folders"
  default     = "k8s-folder"
}

variable "yc_zone" {
  type        = string
  description = "Yandex Cloud zone"
  default     = "ru-central1-d"
}

variable "yc_region" {
  type        = string
  description = "Yandex Cloud region"
  default     = "ru-central1"
}

variable "k8s_version" {
  type = string
  description = "K8s version"
  default     = "1.28"
}

variable "k8s_cluster_name" {
  type = string
  description = "K8s cluster name"
  default     = "k8s-cluster"
}

variable "vpc_network_name" {
  type = string
  description = "VPC network name"
  default     = "k8s-network"
}

variable "subnet_name" {
  type = string
  description = "VPC subnet name"
  default     = "k8s-subnet"
}

variable "subnet_cidrs" {
  type = list(string)
  description = "CIDR subnet"
  default     = ["10.10.0.0/16"]
}
