resource "yandex_compute_instance" "master" {
  count       = var.vm.master.count
  name        = "${var.vm.master.name}${format("%1d", count.index + 1)}"
  hostname    = "${var.vm.master.name}${format("%1d", count.index + 1)}"
  platform_id = var.vm.master.platform_id
  zone        = var.yc.zone
  folder_id   = var.yc.folder.id

  resources {
    cores         = var.vm.master.cpu
    memory        = var.vm.master.memory
    core_fraction = var.vm.master.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.vm.master.image.id
      size     = var.vm.master.disk.size
      type     = var.vm.master.disk.type
    }
  }

  network_interface {
   subnet_id          = yandex_vpc_subnet.k8s_subnet.id
   nat                = count.index==0 ? true : false
  #  ip_address         = var.vm.master.ip_address
   nat_ip_address     = count.index==0 ? yandex_vpc_address.vmaddr.external_ipv4_address[0].address : ""
  }

  metadata = {
    ssh-keys   = "${var.user.name}:${file(var.user.ssh.public_key)}"
    user-data  = count.index != 0 ? "#cloud-config\nssh_authorized_keys:\n- ${tls_private_key.k8s_key.public_key_openssh}" : "#cloud-config\nhostname: master01\nwrite_files:\n- path: /home/${var.user.name}/.ssh/id_ed25519\n  defer: true\n  permissions: 0600\n  owner: ${var.user.name}:${var.user.name}\n  encoding: b64\n  content: ${base64encode("${tls_private_key.k8s_key.private_key_openssh}")}\n- path: /home/${var.user.name}/.ssh/id_ed25519.pub\n  defer: true\n  permissions: 0600\n  owner: ${var.user.name}:${var.user.name}\n  encoding: b64\n  content: ${base64encode("${tls_private_key.k8s_key.public_key_openssh}")}"
    node_index = "${format("%1d", count.index + 1)}"
    etcd_member_name = "etcd${format("%1d", count.index + 1)}"
  }

  allow_stopping_for_update = var.vm.master.allow_stopping_for_update
}

resource "yandex_compute_instance" "worker" {
  count       = var.vm.worker.count
  name        = "${var.vm.worker.name}${format("%1d", count.index + 1)}"
  hostname    = "${var.vm.worker.name}${format("%1d", count.index + 1)}"
  platform_id = var.vm.worker.platform_id
  zone        = var.yc.zone
  folder_id   = var.yc.folder.id

  resources {
    cores         = var.vm.worker.cpu
    memory        = var.vm.worker.memory
    core_fraction = var.vm.worker.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.vm.worker.image.id
      size     = var.vm.worker.disk.size
      type     = var.vm.worker.disk.type
    }
  }

  network_interface {
   subnet_id          = yandex_vpc_subnet.k8s_subnet.id
  }

  metadata = {
    ssh-keys  = "${var.user.name}:${file(var.user.ssh.public_key)}"
    user-data = "#cloud-config\nssh_authorized_keys:\n- ${tls_private_key.k8s_key.public_key_openssh}"
    node_index = "${format("%1d", count.index + 1)}"
  }

  allow_stopping_for_update = var.vm.worker.allow_stopping_for_update
}

resource "tls_private_key" "k8s_key" {
  algorithm = "ED25519"
  # rsa_bits  = 2048
}
