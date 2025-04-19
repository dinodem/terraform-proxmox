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
  base_vm_id = 799
  vm_configs = {
    "test-vpn" = {
      memory         = 4048
      cpu_cores      = 2
      cpu_type       = "x86-64-v2-AES"
      
      # Multiple disks configuration
      disks = [
        {
          interface    = "scsi0"
          size         = 45
          file_format  = "raw"
          datastore_id = "SSD"
        },
        {
          interface    = "scsi1"
          size         = 25
          file_format  = "raw"
          datastore_id = "SSD" # Specific datastore for this disk
        }
      ]
      
      # Multiple network devices
      network_devices = [
        {
          bridge  = "vmbr0"
          model   = "virtio"
          enabled = true
          vlan_id    = 100  # Support for VLAN ID
        },
        {
          bridge  = "vmbr0"
          model   = "virtio"
          enabled = true
        }
      ]
      # Multiple IP configurations
      # This is a list of objects, each containing address and gateway
      ip_configs = [
        {
          address = "10.10.0.193/24"
          gateway = "10.10.0.1"
        },
        {
          address = "10.10.0.194/24"
          gateway = "10.10.0.1"
        }
      ]
      
      ssh_keys       = ["ssh-ed25519 AAAAC3NzaC1l...@example.com"]
      dns_servers    = ["10.10.0.237"]  ## Comment out if you want to use default value from variables 1.1.1.1, 1.0.0.1
      #  vga_type       = "serial0" ## Uncomment to override default value for vga_type
      #  vga_memory     = 16 ## Uncomment to override default value for vga_memory
      template_vm_id = 9001 ### Comment out if you want to use default value from variables
    }
  }

  # Generate VM IDs sequentially
  vm_ids = { for idx, name in sort(keys(local.vm_configs)) :
    name => local.base_vm_id + idx
  }
}
