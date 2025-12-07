output "public_ip_address" {
  description = "Public address to connect to"
  value       = yandex_compute_instance.master[*].network_interface[0].nat_ip_address
}

output "master-info" {
  description = "General information about created VMs"
  value = {
    for vm in yandex_compute_instance.master :
    vm.name => {
      ip_address     = vm.network_interface.*.ip_address
      nat_ip_address = vm.network_interface.*.nat_ip_address
    }
  }
}

output "worker-info" {
  description = "General information about created VMs"
  value = {
    for vm in yandex_compute_instance.worker :
    vm.name => {
      ip_address     = vm.network_interface.*.ip_address
      nat_ip_address = vm.network_interface.*.nat_ip_address
    }
  }
}

