resource "yandex_kubernetes_node_group" "workload_nodes" {
  cluster_id  = "${yandex_kubernetes_cluster.k8s_cluster.id}"
  name        = "workload-nodes"
  description = "Workload nodes group"
  version     = var.k8s_version

  labels = {
    "nodes-group" = "workload"
  }

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
      size = 1
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

resource "yandex_kubernetes_node_group" "infra_nodes" {
  cluster_id  = "${yandex_kubernetes_cluster.k8s_cluster.id}"
  name        = "infra-nodes"
  description = "Infra nodes group"
  version     = var.k8s_version

  node_labels = {
    "node-role" = "infra"
  }

  node_taints = [
    "node-role=infra:NoSchedule"
  ]

  labels = {
    "nodes-group" = "infra"
  }

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
      size = 1
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