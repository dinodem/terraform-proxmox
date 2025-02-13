terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.71.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.vm_name
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = var.description

  clone {
    vm_id = var.template_vm_id
  }

  agent {
    enabled = true
  }

  memory {
    dedicated = var.memory
  }

  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size
  }

initialization {
  dns {
    servers = var.dns_servers
  }

  ip_config {
    ipv4 {
      address = var.ipv4_address
      gateway = var.ipv4_gateway
    }
  }

  user_account {
    keys     = var.ssh_public_keys
    username = var.vm_username
    password = var.vm_password
  }
}
}
