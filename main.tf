terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.71.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://10.10.0.198:8006"
  insecure = true
}

resource "random_password" "vm_password" {
  length  = 32
  special = true
}

module "proxmox_vms" {
  source = "./modules/vm"
  vm_configs = { for name, config in local.vm_configs : 
    name => merge(config, { vm_id = local.vm_ids[name] })
  }
  node_name    = "pve" ## Set your node name.
  vm_password  = random_password.vm_password.result
 # vm_username  = "username" ## Uncomment to override default username from variables ubuntu
}

locals {
  base_vm_id = 599
  vm_configs = {
    "server-clone-1" = {
      memory         = 8192
      cpu_cores      = 2
      cpu_type       = "x86-64-v2-AES"
      disk_size      = 55
      ssh_keys       = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL/8VzmhjGiVwF5uRj4TXWG0M8XcCLN0328QkY0kqkNj @example"]
      ipv4_address   = "10.10.0.189/24"
      ipv4_gateway   = "10.10.0.1"
      dns_servers    = ["10.10.0.100"]  ## Comment out if you want to use default value from variables 1.1.1.1, 1.0.0.1 
    #  vga_type       = "serial0" ## Uncomment to override default value for vga_type
    #  vga_memory     = 16 ## Uncomment to override default value for vga_memory
    #  template_vm_id = 9000 ### Comment out if you want to use default value from variables
    }
    "server-clone-2" = {
      memory         = 4096
      cpu_cores      = 1
      cpu_type       = "x86-64-v2-AES"
      disk_size      = 40
      ssh_keys       = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL/8VzmhjGiVwF5uRj4TXWG0M8XcCLN0328QkY0kqkNj @example"]
      ipv4_address   = "10.10.0.190/24"
      ipv4_gateway   = "10.10.0.1"
      dns_servers    = ["1.1.1.1", "1.0.0.1"]   
    #  vga_type       = "serial0" ## Uncomment to override default value for vga_type
    #  vga_memory     = 16 ## Uncomment to override default value for vga_memoryy
      template_vm_id = 9000
    }
  }

  # Generate VM IDs sequentially
  vm_ids = { for idx, name in sort(keys(local.vm_configs)) : 
    name => local.base_vm_id + idx 
  }
}
