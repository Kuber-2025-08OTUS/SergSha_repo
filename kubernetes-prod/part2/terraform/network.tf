resource "yandex_vpc_network" "k8s_network" {
  name      = var.network.name
  # folder_id = yandex_resourcemanager_folder.yc_folder.id
}

resource "yandex_vpc_subnet" "k8s_subnet" {
  name           = var.subnet.name
  # folder_id      = yandex_resourcemanager_folder.yc_folder.id
  v4_cidr_blocks = var.subnet.cidr
  zone           = var.yc.zone
  network_id     = yandex_vpc_network.k8s_network.id
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name      = "default-gateway"
  # folder_id = yandex_resourcemanager_folder.yc_folder.id
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name       = "main-route-table"
  # folder_id  = yandex_resourcemanager_folder.yc_folder.id
  network_id = yandex_vpc_network.k8s_network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_address" "vmaddr" {
  name = "vmaddr"
  deletion_protection = false
  external_ipv4_address {
    zone_id = var.yc.zone
  }
}