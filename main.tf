terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.71.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://some-ip-or-dns-goes-here:8006"
  #username = var.virtual_environment_username  (Uncomment in case you want to use variables, otherwise just export the username and password)
  #password = var.virtual_environment_password

### Want to use plain username and password? Uncomment and set username and password.
#  username = "username@realm"
#  password = "a-strong-password"

  insecure = true
}

module "proxmox_vms" {
  for_each = local.vm_configs
  ipv4_address = each.value.ipv4_address
  ipv4_gateway = each.value.ipv4_gateway
  cpu_cores = each.value.cpu_cores
  cpu_type  = each.value.cpu_type
  
  source = "./modules/vm"

  vm_name        = each.key
  node_name      = "pve"
  vm_id          = local.vm_ids[each.key]
  template_vm_id = 9000  # Replace with your template VM ID
  memory         = each.value.memory
  ssh_public_keys = each.value.ssh_keys
  disk_size      = 20
  datastore_id   = "local-lvm"
}

resource "random_password" "vm_password" {
  length  = 32
  special = true
}



locals {
  base_vm_id = 1001  # Starting ID
  vm_configs = {
    "ubuntu-clone-1" = {
      memory    = 768
      cpu_cores = 2
      cpu_type  = "x86-64-v2-AES"
      ssh_keys  = ["ssh-ed25519 AAAAC3Nza..."]
      ipv4_address = "10.10.0.189/24"
      ipv4_gateway = "10.10.0.1"
    },
    "ubuntu-clone-2" = {
      memory    = 1024
      cpu_cores = 2
      cpu_type  = "x86-64-v2-AES"
      ssh_keys  = ["ssh-ed25519 AAAAC3Nza..."]
      ipv4_address = "10.10.0.190/24"
      ipv4_gateway = "10.10.0.1"
    }
  }

  # Generate VM IDs sequentially
  vm_ids = { for idx, name in sort(keys(local.vm_configs)) : 
    name => local.base_vm_id + idx 
  }
}
