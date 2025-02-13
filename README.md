# Terraform / OpenTofu module for Proxmox

### How to use

!! You need to have templete, or create with terraform https://registry.terraform.io/providers/bpg/proxmox/latest/docs/guides/cloud-image

```
Change the following in the root main.tf

  endpoint = "https://some-ip-or-dns-goes-here:8006"

  Export username and password:
  export PROXMOX_VE_USERNAME="username@realm"
  export PROXMOX_VE_PASSWORD='a-strong-password'

 The variable values can be provided via a separate .tfvars file that should be gitignored. See the Terraform documentation for more information.

  Change the following to your enviroment: 

  
  node_name      = "pve" (name of your proxmox node)
  template_vm_id = 9000 (id of the templete)
  disk_size      = 20 (disk size)
  datastore_id   = "local-lvm" (name of the datastore in your proxmox)

```
### How to deploy/clone VM
```
Change VM info, such as IP range, SSH-Keys (if no SSH-Keys are added there will be a random ssh generated, same with password.)

Open the ./modules/vm/variables.tf and set your defaults, such as cpu, ram, disk, username..

The keys are added to user "ubuntu".

This is where you specify the vm and how many you want to clone from your templete.

ubuntu-clone-1 = name of the vm.

locals {
  vms = {
    "ubuntu-clone-1" = {
      vm_id    = 1001
      memory   = 768
      cpu_cores    = 2
      cpu_type     = "x86-64-v2-AES"
      ssh_keys = [
        "ssh-ed25519..",  
      ]     
      ipv4_address = "10.10.0.189/24"  
      ipv4_gateway = "10.10.0.1"    
    },
    "ubuntu-clone-2" = {
      vm_id    = 1002
      memory   = 1024
      cpu_cores    = 2
      cpu_type     = "x86-64-v2-AES"
      ssh_keys = [
        "ssh-ed25519...",
      ]
      ipv4_address = "10.10.0.190/24"
      ipv4_gateway = "10.10.0.1"
    }
  }
}

```

### OpenTofu / Terraform deployment
Run `tofu init`
Allow tofu or terraform to install the providers.
Run `tofu plan` and then `tofu apply`

To see the random generated password: `tofu output -json | jq .` 

### Don't want to clone but want to use the module?

Update the main.tf chang the source = "./modules/vm" to point to the git repo module.

`source = "https://github.com/dinodem/proxmox-terraform/tree/main/modules/vm"`
