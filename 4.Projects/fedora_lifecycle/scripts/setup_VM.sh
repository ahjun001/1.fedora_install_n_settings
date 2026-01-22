#!/usr/bin/env bash
# util_template.sh
set -euo pipefail

# Source _config.sh to get STORAGE_SOURCE
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_config.sh"

NAME=$(build_filename "VM-set")

# Check if domain is defined using virsh dominfo (works for inactive domains)
if ! virsh dominfo "$NAME" &>/dev/null; then
    echo "Domain $NAME is not defined. Cleaning up leftover files..."

    # Define file paths (adjust path if needed, e.g., /etc/libvirt/qemu/, /var/lib/libvirt/images/)
    xml_file="/etc/libvirt/qemu/${NAME}.xml"
    DISK_FILE="$STORAGE_POOL/${NAME}.qcow2"

    # Remove XML file if it exists
    if [ -f "$xml_file" ]; then rm -vf "$xml_file"; fi

    # Remove QCOW2 disk file if it exists
    if [ -f "$DISK_FILE" ]; then sudo rm -vf "$DISK_FILE"; fi
else
    echo "Domain $NAME is still defined. No files deleted. Exiting ..."
    exit 1
fi

virt-install \
    --disk path="${DISK_FILE}",size=40,bus=virtio,format=qcow2,discard=unmap,boot_order=1 \
    --disk path="${STORAGE_POOL}/${CDROM}",device=cdrom,bus=sata,readonly=on,boot_order=2 \
    --os-variant "$OS_VARIANT" \
    --memory 8192 \
    --vcpus 12,placement=static \
    --name "$NAME" \
    --network bridge=virbr0,model=virtio \
    --machine q35 \
    --boot uefi,loader=/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd,loader_type=pflash,loader_secure=yes,nvram_template=/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd \
    --clock offset=localtime \
    --graphics spice,listen=127.0.0.1,clipboard.copypaste=yes \
    --features acpi=on,apic=on,vmport=off,smm=on

virsh change-media "$NAME" sda --eject

echo Listing files:
sudo find "${STORAGE_POOL}" -type f -name "$NAME".qcow2 -exec ls -l {} \;
sudo find "${QEMU_CONF_DIR}" -type f -name "$NAME".xml -exec ls -l {} \;
