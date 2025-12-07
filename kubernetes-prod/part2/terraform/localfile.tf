resource "local_file" "ansible_cfg" {
  content = templatefile("${path.module}/templates/ansible.cfg.tftpl",
    {
      user = var.user
      master = yandex_compute_instance.master
    }
  )
  filename = "${path.module}/../kubespray/ansible.cfg"
}

resource "local_file" "inventory_ini" {
  content = templatefile("${path.module}/templates/inventory.ini.tftpl",
    {
      master = yandex_compute_instance.master
      worker = yandex_compute_instance.worker
      remote_user  = var.user.name
    }
  )
  filename = "${path.module}/../kubespray/inventory/mycluster/inventory.ini"
}