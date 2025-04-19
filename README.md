# Proxmox VM OpenTofu / Terraform Module

This module helps you easily create and manage multiple Virtual Machines in Proxmox using OpenTofu or Terraform. It supports multiple disks, network interfaces with VLAN tagging, and IP configurations.

## Creating Ubuntu Cloud Image Template

Copy/clone the script to your Proxmox server, make it executable `chmod +x ubuntu-template-creator.sh`, then run the script from the Proxmox console or SSH `./ubuntu-template-creator.sh`. Choose your storage, Ubuntu flavor, and let the script do the rest for you. Adjust the template ID in your main.tf to use it for deploying VMs.

```bash
============================================
   Proxmox Ubuntu Template Creator Script   
============================================

This script will help you create an Ubuntu cloud image template on your Proxmox server.
You will be prompted for some configuration options.


===== Prerequisites Check =====
==> Checking for required packages...
==> libguestfs-tools is already installed.

===== Configuration Options =====
Available storages on this Proxmox server:
  - SSD
  - local-lvm

Enter the storage name to use [default: local-zfs]: SSD
==> Using storage: SSD
Enter VM ID for the template [default: 9000]: 9001
==> Using VM ID: 9001
Enter a name for the template [default: ubuntu-cloud-template]: ubuntu-template
==> Using VM name: ubuntu-template

Available Ubuntu versions:
  1) Plucky (24.10) [default]
  2) Noble (24.04 LTS)
  3) Jammy (22.04 LTS)
  4) Focal (20.04 LTS)
Select Ubuntu version [1-4]: 1
==> Selected Ubuntu Plucky (24.10)
Enter memory size in MB [default: 2048]: 
Enter number of CPU cores [default: 2]: 
==> VM Resources: 2048 MB RAM, 2 cores

===== Review Configuration =====
Please review your settings:
  Storage:       SSD
  VM ID:         9001
  VM Name:       ubuntu-template
  Ubuntu:        plucky
  Memory:        2048 MB
  CPU Cores:     2

```

## Getting Started

### Prerequisites

1. Install [OpenTofu](https://opentofu.org/docs/intro/install/) (version 1.0.0 or later)
2. Have access to a Proxmox server

### Setting Up Your Project

There are two ways to use this module:

#### Method 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/dinodem/terraform-proxmox.git
cd terraform-proxmox

# Create your configuration file
touch main.tf

# Open main.tf in your editor and add your configuration
```

### Authentication with Proxmox
Read more here: https://registry.terraform.io/providers/bpg/proxmox/latest/docs#authentication-methods-comparison
Before using this module, you need to provide your Proxmox credentials. You have three options:

#### Option 1: Environment Variables (Recommended for Development)

```bash
export PROXMOX_VE_ENDPOINT="https://your-proxmox-server:8006"
export PROXMOX_VE_USERNAME="root@pam"
export PROXMOX_VE_PASSWORD="your-password-here"
export PROXMOX_VE_INSECURE="true"  # Only use if you have self-signed certificates
```

#### Option 2: OpenTofu Variables

1. Define variables in `variables.tf`:

```terraform
variable "proxmox_endpoint" {
  description = "The Proxmox API endpoint"
  type        = string
}

variable "proxmox_username" {
  description = "Username for Proxmox authentication"
  type        = string
}

variable "proxmox_password" {
  description = "Password for Proxmox authentication"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = false
}
```

2. Use the variables in `main.tf`:

```terraform
provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
}
```

3. Create a `terraform.tfvars` file (add to .gitignore):

```terraform
proxmox_endpoint  = "https://your-proxmox-server:8006"
proxmox_username  = "root@pam"
proxmox_password  = "your-password-here"
proxmox_insecure  = true
```

#### Option 3: API Tokens (Recommended for Production)

```bash
export PROXMOX_VE_ENDPOINT="https://your-proxmox-server:8006"
export PROXMOX_VE_API_TOKEN="terraform@pve!provider=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

## Using the Module

### Basic Configuration

Create a `main.tf` file in your project root:

```terraform
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.71.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://your-proxmox-server:8006"
  insecure = true
  # Authentication will use environment variables
}

module "proxmox_vms" {
  source = "./modules/vm"
  
  node_name   = "pve"  # Your Proxmox node name
  vm_password = "your-vm-password"  # Or use random_password
  
  vm_configs = {
    "web-server" = {
      vm_id     = 100
      memory    = 4096
      cpu_cores = 2
      cpu_type  = "host"
      
      disks = [
        {
          interface    = "scsi0"
          size         = 20  # 20GB
          file_format  = "raw"
          datastore_id = "local-lvm"
        }
      ]
      
      network_devices = [
        {
          bridge  = "vmbr0"
          model   = "virtio"
          enabled = true
          vlan    = null  # No VLAN tagging
        }
      ]
      
      ip_configs = [
        {
          address = "192.168.1.100/24"
          gateway = "192.168.1.1"
        }
      ]
      
      ssh_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."]
    }
  }
}
```

### Running OpenTofu Commands

```bash
# Initialize
tofu init

# Preview changes
tofu plan

# Apply changes
tofu apply

# Remove resources
tofu destroy
```

## Advanced Features

### Multiple Disks

```terraform
disks = [
  {
    interface    = "scsi0"
    size         = 20  # System disk (20GB)
    file_format  = "raw"
    datastore_id = "SSD"
  },
  {
    interface    = "scsi1"
    size         = 100  # Data disk (100GB)
    file_format  = "raw"
    datastore_id = "HDD"
  }
]
```

### Multiple Network Interfaces with VLAN Support

```terraform
network_devices = [
  {
    bridge  = "vmbr0"
    model   = "virtio"
    enabled = true
    vlan    = 100  # Assign to VLAN 100
  },
  {
    bridge  = "vmbr0"
    model   = "virtio"
    enabled = true
    vlan    = 200  # Assign to VLAN 200
  }
]

# Each network device needs its own IP configuration
ip_configs = [
  {
    address = "192.168.100.10/24"  # IP on VLAN 100
    gateway = "192.168.100.1"
  },
  {
    address = "192.168.200.10/24"  # IP on VLAN 200
    gateway = "192.168.200.1"
  }
]
```

### Multiple VMs

```terraform
vm_configs = {
  "web-server" = {
    vm_id     = 100
    memory    = 4096
    cpu_cores = 2
    # ... other configurations
  },
  "database" = {
    vm_id     = 101
    memory    = 8192
    cpu_cores = 4
    # ... other configurations
  }
}
```

## Complete Example

```terraform
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
  # Authentication through environment variables
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
  node_name    = "pve"
  vm_password  = random_password.vm_password.result
}

locals {
  base_vm_id = 699
  vm_configs = {
    "web-server" = {
      memory    = 4096
      cpu_cores = 2
      cpu_type  = "host"
      
      disks = [
        {
          interface    = "scsi0"
          size         = 20
          file_format  = "raw"
          datastore_id = null  # Uses default
        }
      ]
      
      network_devices = [
        {
          bridge  = "vmbr0"
          model   = "virtio"
          enabled = true
          vlan    = 10  # VLAN 10 for web servers
        }
      ]
      
      ip_configs = [
        {
          address = "192.168.10.100/24"
          gateway = "192.168.10.1"
        }
      ]
      
      ssh_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."]
    },
    
    "database" = {
      memory    = 8192
      cpu_cores = 4
      cpu_type  = "host"
      
      disks = [
        {
          interface    = "scsi0"
          size         = 40
          file_format  = "raw"
          datastore_id = null
        },
        {
          interface    = "scsi1"
          size         = 200
          file_format  = "raw"
          datastore_id = "HDD"
        }
      ]
      
      network_devices = [
        {
          bridge  = "vmbr0"
          model   = "virtio"
          enabled = true
          vlan    = 20  # VLAN 20 for databases
        }
      ]
      
      ip_configs = [
        {
          address = "192.168.20.100/24"
          gateway = "192.168.20.1"
        }
      ]
      
      ssh_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."]
    }
  }

  # Generate VM IDs automatically
  vm_ids = { for idx, name in sort(keys(local.vm_configs)) :
    name => local.base_vm_id + idx
  }
}
```

## Configuration Reference

### VM Configuration Options

| Setting | Description | Default |
|---------|-------------|---------|
| `vm_id` | Unique ID for the VM | Required |
| `memory` | RAM in MB | Required |
| `cpu_cores` | Number of CPU cores | Required |
| `cpu_type` | CPU type | Required |
| `disks` | List of disk objects | Required |
| `network_devices` | List of network device objects | Required |
| `ip_configs` | List of IP configuration objects | Required |
| `ssh_keys` | List of SSH public keys | Required |
| `dns_servers` | List of DNS servers | `["1.1.1.1", "1.0.0.1"]` |
| `vga_type` | VGA type | `"serial0"` |
| `vga_memory` | VGA memory in MB | `16` |
| `template_vm_id` | Template VM ID to clone from | `9000` |

### Disk Configuration

| Setting | Description | Default |
|---------|-------------|---------|
| `interface` | Disk interface (e.g., scsi0, scsi1) | Required |
| `size` | Disk size in GB | Required |
| `file_format` | Disk format | `"raw"` |
| `datastore_id` | Storage location | Module default |

### Network Device Configuration

| Setting | Description | Default |
|---------|-------------|---------|
| `bridge` | Network bridge | `"vmbr0"` |
| `model` | Network device model | `"virtio"` |
| `enabled` | Whether network is enabled | `true` |
| `vlan` | VLAN tag (1-4094) | `null` (no VLAN) |

### IP Configuration

| Setting | Description | Default |
|---------|-------------|---------|
| `address` | IP address with subnet (CIDR notation) | Required |
| `gateway` | Gateway IP address | Required |

## Retrieving VM Password

If you used `random_password` to generate a password, you can see it with:

```bash
tofu output -raw vm_password
```