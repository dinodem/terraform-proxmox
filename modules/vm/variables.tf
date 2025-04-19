variable "dns_servers" {
  type        = list(string)
  default     = ["1.1.1.1", "1.0.0.1"] # Default DNS servers
  description = "DNS servers for the VMs"
}

variable "vga_type" {
  type        = string
  default     = "serial0"
  description = "Default VGA type for VMs"
}

variable "vga_memory" {
  type        = number
  default     = 16
  description = "Default VGA memory for VMs"
}

variable "node_name" {
  type = string
}

variable "datastore_id" {
  type    = string
  default = "SSD"
}

variable "vm_password" {
  type = string
}

variable "vm_username" {
  type    = string
  default = "ubuntu"
}

variable "template_vm_id" {
  type        = number
  default     = 9000 # Default template VM ID
  description = "Default template VM ID for cloning"
}

# Define the disk object
variable "vm_configs" {
  type = map(object({
    vm_id          = number
    memory         = number
    cpu_cores      = number
    cpu_type       = string
    

    disks = list(object({
      datastore_id = optional(string)
      interface    = string
      size         = number
      file_format  = optional(string, "raw")
    }))

    network_devices = list(object({
      bridge  = optional(string)
      model   = optional(string)
      enabled = optional(bool)
      vlan_id = optional(number) 
    }))
    
    ip_configs = list(object({
      address = string
      gateway = string
    }))
    
    dns_servers    = optional(list(string))
    ssh_keys       = list(string)
    vga_type       = optional(string)
    vga_memory     = optional(number)
    template_vm_id = optional(number)
  }))
  description = "Map of VM configurations"
}