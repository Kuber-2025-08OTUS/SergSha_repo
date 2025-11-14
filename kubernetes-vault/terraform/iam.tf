resource "yandex_iam_service_account" "k8s_cluster_account" {
  name        = "k8s-cluster-account"
  description = "Service account for Kubernetes cluster"
  # folder_id = yandex_resourcemanager_folder.yc_folder.id
}

resource "yandex_iam_service_account" "k8s_node_account" {
  name        = "k8s-node-account"
  description = "Service account for Kubernetes nodes"
  # folder_id = yandex_resourcemanager_folder.yc_folder.id
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_role" {
  folder_id = var.yc_folder_id
  # folder_id = yandex_resourcemanager_folder.yc_folder.id
  # role      = "k8s.clusters.agent"
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster_account.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_node_role" {
  folder_id = var.yc_folder_id
  # folder_id = yandex_resourcemanager_folder.yc_folder.id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_node_account.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_node_vpc_role" {
  folder_id = var.yc_folder_id
  # folder_id = yandex_resourcemanager_folder.yc_folder.id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_node_account.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_node_loadbalancer_role" {
  folder_id = var.yc_folder_id
  # folder_id = yandex_resourcemanager_folder.yc_folder.id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_node_account.id}"
}
