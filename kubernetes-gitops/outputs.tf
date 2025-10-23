output "k8s_cluster_id" {
  value = yandex_kubernetes_cluster.k8s_cluster.id
}

output "folder_id" {
  value = var.yc_folder_id
}

output "k8s_cluster_name" {
  value = yandex_kubernetes_cluster.k8s_cluster.name
}

# output "kubeconfig" {
#   value = yandex_kubernetes_cluster.k8s_cluster.master[0].cluster_ca_certificate
#   sensitive = true
# }

output "kubeconfig" {
  value     = yandex_kubernetes_cluster.k8s_cluster.master[0].external_v4_endpoint
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = yandex_kubernetes_cluster.k8s_cluster.master[0].cluster_ca_certificate
  sensitive = true
}