# Terraform / OpenTofu module for Proxmox

## How to use

### Create VM templete with ubuntu cloud image (run in terminal of your proxmox)

Change local-zfs to your storage !!

```
# installing libguestfs-tools only required once, prior to first run
sudo apt update -y
sudo apt install libguestfs-tools -y

wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
sudo virt-customize -a noble-server-cloudimg-amd64.img --install qemu-guest-agent
sudo qm create 9000 --name "noble-server-cloudimg-template" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
sudo qm importdisk 9000 noble-server-cloudimg-amd64.img local-zfs
sudo qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-9000-disk-0
sudo qm set 9000 --boot c --bootdisk scsi0
sudo qm set 9000 --ide2 local-zfs:cloudinit
sudo qm set 9000 --serial0 socket --vga serial0
sudo qm set 9000 --agent enabled=1
sudo qm template 9000
rm noble-server-cloudimg-amd64.img

```
## Clone repo and change following:

```
## main.tf

endpoint = "https://proxmox-url:8006" == Set to your Proxmox IP / dns name.

If you are using username and password export it or set it in the .env

export PROXMOX_VE_USERNAME="username@realm"
export PROXMOX_VE_PASSWORD='a-strong-password'

Set your templete ID, if you followed the commands above, the ID should be 9000 in this case no need to change it.

Set node_name and edit the locales for your VMs.

A few lines optional in the vms such as

VGA_TYPE, VGA_MEMORY, DNS_SERVERS and TEMPLATE_VM_ID. They will use default values from modues/vm/variables.tf 

base_mv_id = ID to start with, so first vm will have id 599, second vm will have id 600 and so on.

VGA_TYPE default value is serial0 this needs to be serial0 if you are using ubuntu cloud image or the console won't work.

```

### How to deploy/clone VM
```
Adjust the values and save the main.tf

your main.tf must point to the module 

source = "./modules/vm" or source = "git::https://github.com/dinodem/proxmox-terraform/tree/main/modules/vm" if you want to point directly to the Git repository.

server-clone-1 = server name

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

```

### Extend disk on VM

```
Make sure your server has follwoing installed: cloud-initramfs-growroot

```

```

Change the value of the disk_size in locales
Example:
disk_size = 35 > disk_size = 45
Run tofu plan 
The output should be something like this:

```
```
OpenTofu will perform the following actions:

  # module.proxmox_vms["server-clone-1"].proxmox_virtual_environment_vm.vm will be updated in-place
  ~ resource "proxmox_virtual_environment_vm" "vm" {
        id                      = "599"
        name                    = "server-clone-1"
        # (27 unchanged attributes hidden)

      ~ disk {
          ~ size              = 35 -> 45
            # (11 unchanged attributes hidden)
        }

```
So now just run tofu apply and let Terraform/Tofu do the rest, if the server is not resized make sure you have cloud-initramfs-growroot installed, and then just reboot it. 

```

### OpenTofu / Terraform deployment
Run `tofu init`
Allow tofu or terraform to install the providers.
Run `tofu plan` and then `tofu apply`

To see the random generated password: `tofu output -json | jq .` 

### Don't want to clone but want to use the module?

Update the main.tf chang the source = "./modules/vm" to point to the git repo module.

`source = "git::https://github.com/dinodem/proxmox-terraform/tree/main/modules/vm"`

