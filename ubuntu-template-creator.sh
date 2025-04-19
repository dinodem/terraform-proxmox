#!/bin/bash
# Proxmox Ubuntu Cloud Image Template Creator Script
# Run this from the Proxmox console or SSH
# Created by [Dino Demirovic] - https://github.com/dinodem
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'


print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

print_step() {
    echo -e "\n${GREEN}===== $1 =====${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}


check_success() {
    if [ $? -ne 0 ]; then
        print_error "$1"
        exit 1
    fi
}


clear
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   Proxmox Ubuntu Template Creator Script   ${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "\nThis script will help you create an Ubuntu cloud image template on your Proxmox server."
echo -e "You will be prompted for some configuration options.\n"


if [ "$EUID" -ne 0 ]; then
    print_warning "This script needs to be run with sudo or as root."
    echo -e "Please run it again with: ${YELLOW}sudo $0${NC}"
    exit 1
fi


print_step "Prerequisites Check"
print_message "Checking for required packages..."


if ! dpkg -l | grep -q libguestfs-tools; then
    print_message "Installing libguestfs-tools..."
    apt update -y
    apt install libguestfs-tools -y
    check_success "Failed to install libguestfs-tools"
else
    print_message "libguestfs-tools is already installed."
fi


print_step "Configuration Options"


echo -e "Available storages on this Proxmox server:"
pvesm status | grep -v "local\s" | awk 'NR>1 {print "  - " $1}'
echo ""

read -p "Enter the storage name to use [default: local-zfs]: " STORAGE
STORAGE=${STORAGE:-local-zfs}
print_message "Using storage: $STORAGE"


read -p "Enter VM ID for the template [default: 9000]: " VM_ID
VM_ID=${VM_ID:-9000}
print_message "Using VM ID: $VM_ID"


read -p "Enter a name for the template [default: ubuntu-cloud-template]: " VM_NAME
VM_NAME=${VM_NAME:-ubuntu-cloud-template}
print_message "Using VM name: $VM_NAME"


echo -e "\nAvailable Ubuntu versions:"
echo "  1) Plucky (24.10) [default]"
echo "  2) Noble (24.04 LTS)"
echo "  3) Jammy (22.04 LTS)"
echo "  4) Focal (20.04 LTS)"
read -p "Select Ubuntu version [1-4]: " VERSION_CHOICE
case $VERSION_CHOICE in
    2)
        UBUNTU_VERSION="noble"
        print_message "Selected Ubuntu Noble (24.04 LTS)"
        UBUNTU_PATH="${UBUNTU_VERSION}/current"
        ;;
    3)
        UBUNTU_VERSION="jammy"
        print_message "Selected Ubuntu Jammy (22.04 LTS)"
        UBUNTU_PATH="${UBUNTU_VERSION}/current"
        ;;
    4)
        UBUNTU_VERSION="focal"
        print_message "Selected Ubuntu Focal (20.04 LTS)"
        UBUNTU_PATH="${UBUNTU_VERSION}/current"
        ;;
    *)
        UBUNTU_VERSION="plucky"
        print_message "Selected Ubuntu Plucky (24.10)"
        UBUNTU_PATH="${UBUNTU_VERSION}/current"
        ;;
esac


read -p "Enter memory size in MB [default: 2048]: " VM_MEMORY
VM_MEMORY=${VM_MEMORY:-2048}

read -p "Enter number of CPU cores [default: 2]: " VM_CORES
VM_CORES=${VM_CORES:-2}

print_message "VM Resources: $VM_MEMORY MB RAM, $VM_CORES cores"


print_step "Review Configuration"
echo -e "Please review your settings:"
echo -e "  Storage:       ${YELLOW}$STORAGE${NC}"
echo -e "  VM ID:         ${YELLOW}$VM_ID${NC}"
echo -e "  VM Name:       ${YELLOW}$VM_NAME${NC}"
echo -e "  Ubuntu:        ${YELLOW}$UBUNTU_VERSION${NC}"
echo -e "  Memory:        ${YELLOW}$VM_MEMORY MB${NC}"
echo -e "  CPU Cores:     ${YELLOW}$VM_CORES${NC}"
echo ""

read -p "Do you want to proceed with these settings? (y/n) [default: y]: " CONFIRM
CONFIRM=${CONFIRM:-y}

if [[ $CONFIRM != [Yy]* ]]; then
    print_message "Template creation cancelled."
    exit 0
fi


print_step "Creating Ubuntu Template"

IMAGE_FILE="${UBUNTU_VERSION}-server-cloudimg-amd64.img"
IMAGE_URL="https://cloud-images.ubuntu.com/${UBUNTU_PATH}/${IMAGE_FILE}"

print_message "Downloading Ubuntu cloud image from ${IMAGE_URL}..."
wget "$IMAGE_URL"
check_success "Failed to download the cloud image"

print_message "Installing qemu-guest-agent in the image..."
virt-customize -a "$IMAGE_FILE" --install qemu-guest-agent
check_success "Failed to install qemu-guest-agent"


print_message "Creating VM with ID $VM_ID..."
qm create $VM_ID --name "$VM_NAME" --memory $VM_MEMORY --cores $VM_CORES --net0 virtio,bridge=vmbr0
check_success "Failed to create VM"

print_message "Importing disk to $STORAGE..."
qm importdisk $VM_ID "$IMAGE_FILE" $STORAGE
check_success "Failed to import disk"

print_message "Configuring VM settings..."
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:vm-${VM_ID}-disk-0
check_success "Failed to configure disk"

qm set $VM_ID --boot c --bootdisk scsi0
check_success "Failed to configure boot options"

qm set $VM_ID --ide2 ${STORAGE}:cloudinit
check_success "Failed to add cloudinit drive"

qm set $VM_ID --serial0 socket --vga serial0
check_success "Failed to configure serial port"

qm set $VM_ID --agent enabled=1
check_success "Failed to enable qemu-guest-agent"

print_message "Converting VM to template..."
qm template $VM_ID
check_success "Failed to convert VM to template"


print_message "Cleaning up downloaded files..."
rm "$IMAGE_FILE"
check_success "Failed to clean up files"


print_step "Template Creation Complete"
echo -e "Your Ubuntu ${YELLOW}$UBUNTU_VERSION${NC} template has been created successfully!"
echo -e "Template ID: ${YELLOW}$VM_ID${NC}"
echo -e "Template Name: ${YELLOW}$VM_NAME${NC}"
echo -e "\nYou can now use this template to create new VMs using OpenTofu with this module."
echo -e "Make sure to set ${YELLOW}template_vm_id = $VM_ID${NC} in your tofu / terraform configuration.\n"

echo -e "${GREEN}Thank you for using the Proxmox Ubuntu Template Creator!${NC}"