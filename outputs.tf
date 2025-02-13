output "vm_ipv4_addresses" {
  value = {
    for name, vm in module.proxmox_vms : name => vm.vm_ipv4_address
  }
}

output "vm_password" {
  value     = random_password.vm_password.result
  sensitive = true
}

output "get_sensitive_data" {
  value = "Run the command tofu output -json | jq .vm_password to get the random password."
}
