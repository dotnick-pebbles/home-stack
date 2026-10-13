output "vm_ip" {
  value = proxmox_virtual_environment_vm.vm.ipv4_addresses[1]
}
