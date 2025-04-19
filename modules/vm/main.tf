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

  # Dynamic block for multiple disks
  dynamic "disk" {
    for_each = each.value.disks
    content {
      datastore_id = disk.value.datastore_id != null ? disk.value.datastore_id : var.datastore_id
      interface    = disk.value.interface
      size         = disk.value.size
      file_format  = disk.value.file_format
    }
  }

  vga {
    type   = coalesce(each.value.vga_type, var.vga_type)
    memory = coalesce(each.value.vga_memory, var.vga_memory)
  }

  # Dynamic block for multiple network devices
dynamic "network_device" {
  for_each = each.value.network_devices
  content {
    bridge  = network_device.value.bridge != null ? network_device.value.bridge : "vmbr0"
    model   = network_device.value.model != null ? network_device.value.model : "virtio"
    enabled = network_device.value.enabled != null ? network_device.value.enabled : true
    vlan_id = network_device.value.vlan_id  # Use the vlan_id attribute
  }
}

  agent {
    enabled = true
  }

  initialization {
    # Dynamic block for multiple IP configurations
    dynamic "ip_config" {
      for_each = each.value.ip_configs
      content {
        ipv4 {
          address = ip_config.value.address
          gateway = ip_config.value.gateway
        }
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