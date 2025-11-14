resource "yandex_kubernetes_node_group" "vault_nodes" {
  cluster_id  = "${yandex_kubernetes_cluster.k8s_cluster.id}"
  name        = "vault-nodes"
  description = "vault nodes group"
  version     = var.k8s_version

  node_labels = {
    "node-role" = "vault"
#     "homework"  = "true"
  }

  # node_taints = [
  #   "node-role=vault:NoSchedule"
  # ]

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      # nat        = true
      nat        = false
      subnet_ids = ["${yandex_vpc_subnet.k8s_subnet.id}"]
    }

    resources {
      memory        = 4
      cores         = 2
      core_fraction = 50
    }

    boot_disk {
      type = "network-ssd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
    # auto_scale {
    #   min     = 2
    #   max     = 4
    #   initial = 2
    # }
  }

  allocation_policy {
    location {
      zone = var.yc_zone
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "21:00"
      duration   = "3h"
    }

    maintenance_window {
      day        = "friday"
      start_time = "21:00"
      duration   = "4h30m"
    }
  }
}