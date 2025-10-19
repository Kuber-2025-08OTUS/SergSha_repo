resource "yandex_kubernetes_cluster" "k8s_cluster" {
  name        = var.k8s_cluster_name
  description = "Otus kubernetes cluster"

  # folder_id   = yandex_resourcemanager_folder.yc_folder.id
  network_id = yandex_vpc_network.k8s_network.id

  master {
    version = var.k8s_version # 1.30
    zonal {
      zone      = yandex_vpc_subnet.k8s_subnet.zone
      subnet_id = yandex_vpc_subnet.k8s_subnet.id
    }
    # regional {
    #   region = var.yc_region

    #   location {
    #     zone      = var.yc_zone
    #     subnet_id = yandex_vpc_subnet.k8s_subnet.id
    #   }
    # }
  
    public_ip = true
  
    security_group_ids = [yandex_vpc_security_group.k8s_public_services.id]

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        day        = "monday"
        start_time = "23:00"
        duration   = "3h"
      }
    }
  }

  service_account_id      = yandex_iam_service_account.k8s_cluster_account.id
  node_service_account_id = yandex_iam_service_account.k8s_cluster_account.id

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_cluster_role,
    yandex_resourcemanager_folder_iam_member.k8s_node_role,
  ]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl config delete-context yc-${self.name}
      kubectl config delete-cluster yc-managed-k8s-${self.id}
      kubectl config delete-user yc-managed-k8s-${self.id}
    EOT
  }

  provisioner "local-exec" {
    command = "yc managed-kubernetes cluster get-credentials ${self.id} --external"
  }
}
