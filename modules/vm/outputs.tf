output "vm_ipv4_address" {
  value = length(proxmox_virtual_environment_vm.vm.ipv4_addresses) > 0 ? proxmox_virtual_environment_vm.vm.ipv4_addresses[1][0] : "Only showing IP assigned in this tf state"
}
