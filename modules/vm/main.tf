terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.71.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = var.vm_configs

  name      = each.key
  node_name = var.node_name
  vm_id     = each.value.vm_id

  clone {
    vm_id = coalesce(each.value.template_vm_id, var.template_vm_id)
  }

  memory {
    dedicated = each.value.memory
  }

  cpu {
    cores = each.value.cpu_cores
    type  = each.value.cpu_type
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = each.value.disk_size
  }

  vga {
    type   = coalesce(each.value.vga_type, var.vga_type) 
    memory = coalesce(each.value.vga_memory, var.vga_memory)
  }

  network_device {
    bridge  = "vmbr0"
    model   = "virtio"
    enabled = true
  }

  agent {
    enabled = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = each.value.ipv4_gateway
      }
    }

    dns {
      servers = coalesce(each.value.dns_servers, var.dns_servers)
    }

    user_account {
      username = var.vm_username
      password = var.vm_password
      keys     = each.value.ssh_keys
    }
  }
}
