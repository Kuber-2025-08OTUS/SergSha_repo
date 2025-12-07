resource "local_file" "ansible_cfg" {
  content = templatefile("${path.module}/templates/ansible.cfg.tftpl",
    {
      user = var.user
      master = yandex_compute_instance.master
    }
  )
  filename = "${path.module}/../ansible/ansible.cfg"
}

resource "local_file" "group_vars_all" {
  content = templatefile("${path.module}/templates/group_vars_all.tftpl",
    {
      user = var.user
      k8s  = var.k8s
    }
  )
  filename = "${path.module}/../ansible/group_vars/all.yml"
}

resource "local_file" "inventory_ini" {
  content = templatefile("${path.module}/templates/inventory.ini.tftpl",
    {
      master = yandex_compute_instance.master
      worker = yandex_compute_instance.worker
    }
  )
  filename = "${path.module}/../ansible/inventory.ini"
}

