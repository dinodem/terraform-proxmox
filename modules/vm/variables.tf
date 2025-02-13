variable "vm_name" {
  type        = string
  description = "Name of the VM"
}

variable "description" {
  type        = string
  default     = "Cloned VM"
  description = "Description of the VM"
}

variable "node_name" {
  type        = string
  description = "Proxmox node name"
}

variable "vm_id" {
  type        = number
  description = "VM ID for the new VM"
}

variable "template_vm_id" {
  type        = number
  description = "VM ID of the template to clone"
}

variable "memory" {
  type        = number
  default     = 1024
  description = "Memory allocated to the VM (MB)"
}

variable "cpu_cores" {
  type        = number
  default     = 1
  description = "Number of CPU cores"
}

variable "cpu_type" {
  type        = string
  default     = "host"
  description = "CPU type (e.g., 'host', 'x86-64-v2-AES')"
}

variable "disk_size" {
  type        = number
  default     = 20
  description = "Disk size (GB)"
}

variable "datastore_id" {
  type        = string
  default     = "local-lvm"
  description = "Proxmox storage ID for the disk"
}

variable "dns_servers" {
  type        = list(string)
  default     = ["1.1.1.1"]
  description = "DNS servers for the VM"
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "List of SSH public keys to add to the VM"
  default     = []
}

variable "vm_password" {
  type        = string
  description = "Password for the VM user"
  default     = "ubuntu" ## This will be random, delete the resoruce random_password from ./main.tf and change this to your password.
}

variable "vm_username" {
  type        = string
  description = "Username for the VM"
  default     = "ubuntu" ## This means your SSH keys will be added to this user ! IF you don't change you need to ssh ubuntu@server_ip
}

variable "ipv4_address" {
  type        = string
  description = "Static IPv4 address in CIDR notation (e.g., 192.168.1.10/24)"
}

variable "ipv4_gateway" {
  type        = string
  description = "IPv4 default gateway"
  default     = null
}
