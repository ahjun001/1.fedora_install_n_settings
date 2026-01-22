#!/usr/bin/env bash
# virt_install.sh
set -euo pipefail

# :'
# script to manage VM lifecyle: 4 functions delivering 4 stages
# Deliverables / artefacts are conventionally named as
# f<version>-<spin>_<stage>_<date created>.qcow2

# Then workflow should looks as
# setup_VM - f<version>-<spin>_VM-set_<date created>.qcow2
# install_OS - f<version>-<spin>_OS-installed_<date created>.qcow2
# provision_PKG - f<version>-<spin>_PKG-provisionned_<date created>.qcow2
# upgrade_OS  - f<version>-<spin>_OS-upgraded_<date created>.qcow2
# '
#
# shellcheck source=/dev/null
source "$(dirname "$0")/config.sh"

case $SPIN in
kde)
    # CDROM=Fedora-KDE-Desktop-Live-${VERSION}-1.6.x86_64.iso
    CDROM=Fedora-KDE-Desktop-Live-${VERSION}-1.1.x86_64.iso
    ;;
workstation)
    CDROM="Fedora-Workstation-Live-${VERSION}-1.6.x86_64.iso"
    ;;
kinos)
    CDROM="Fedora-Kinoite-ostree-x86_64-${VERSION}-1.6.iso"
    ;;
*) exit 1 ;;
esac

name() { # name $ARTEFACT
    local STAGE
    STAGE=$1
    case "$STAGE" in
    VM-set | OS-installed | PKG-provisioned | OS-upgraded)
        NAME="f${VERSION}-${SPIN}_${STAGE}_${DATE}"
        ;;
    *)
        echo -e 'Naming convention not respected, exiting ...\n' >&2
        exit 1
        ;;
    esac
}

status() {
    echo -e "
    Version = $VERSION , spin = $SPIN"
    sudo find "$STORAGE_POOL" -type f -name f"${VERSION}"-"${SPIN}"*.qcow2 -printf "%P\n"

    for STAGE in VM-set OS-installed PKG-provisionned OS-upgraded; do
        echo -e "\n${STAGE}"
        sudo find "$STORAGE_POOL" -type f -name f"${VERSION}"-"${SPIN}"_${STAGE}*.qcow2 -printf "%P\n"
    done

}

setup_VM_no_use_until_bug_is_fixed() { # setup_VM $NAME
    # setup_VM will create f<version>-<spin>_VM-set_<date created>.qcow2

    virt-install \
        --name "$1" \
        --memory 8192 \
        --vcpus 12 \
        --disk size=40,bus=virtio \
        --cdrom "$STORAGE_POOL/$CDROM" \
        --os-variant fedora-unknown \
        --graphics spice \
        --channel spicevmc \
        --virt-type kvm \
        --machine q35 \
        --clock offset=localtime \
        --noautoconsole \
        --boot uefi, loader=/usr/share/edk2/ovmf/OVMF_CODE_4M.fd, loader_type=pflash, nvram_template=/usr/share/edk2/ovmf/OVMF_VARS_4M.fd |
        sudo tee "${STORAGE_POOL}/$1.xml" >/dev/null

    # Define the VM from the generated XML without starting it
    virsh define "${STORAGE_POOL}/$1.xml"
}

setup_VM() { # setup_VM $NAME
    # setup_VM will create f<version>-<spin>_VM-set_<date created>.qcow2

    virt-install \
        --name "$1" \
        --memory 2048 \
        --vcpus 2 \
        --disk size=20,bus=virtio \
        --cdrom "$STORAGE_POOL/$CDROM" \
        --os-variant fedora-unknown \
        --graphics spice \
        --channel spicevmc \
        --virt-type kvm \
        --machine q35 \
        --clock offset=localtime \
        --boot uefi \
        --noautoconsole

    virsh dumpxml "$1" | sudo tee "${STORAGE_POOL}/$1.xml" >/dev/null
}

setup_VM_groq() {
    #!/usr/bin/env bash
    # ------------------------------------------------------------
    #  Create a VM that is byte‑for‑byte identical to f42‑kde‑manual
    # ------------------------------------------------------------

    virt-install \
        --name "%1" \
        --uuid dbfd178e-4065-4776-9a22-cb4358afc7a7 \
        --memory 8192 \
        --vcpus 12,placement=static \
        --cpu host-passthrough,check=none,migratable=on \
        --clock offset=utc \
        --boot "uefi,loader=/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd,loader_type=pflash,loader_readonly=yes,loader_secure=yes,nvram_template=/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd" \
        --features acpi=on,apic=on,vmport=off,smm=on \
        --emulator /usr/bin/qemu-system-x86_64 \
        --disk path="$STORAGE_POOL"/f42-kde-manual.qcow2, \
        format=qcow2,bus=virtio,discard=unmap,device=disk, \
        address=pci:0000:04:00.0 \
        --disk path=/path/to/your/iso.iso,device=cdrom,bus=sata,readonly=yes, \
        address=drive:controller=0,bus=0,target=0,unit=0 \
        --controller type=usb,model=qemu-xhci,ports=15,index=0, \
        address=pci:0000:02:00.0 \
        \
        --controller type=pci,model=pcie-root,index=0 \
        \
        --controller type=pci,model=pcie-root-port,index=1, \
        target.chassis=1,target.port=0x10, \
        address=pci:0000:00:02.0,multifunction=on \
        \
        --controller type=pci,model=pcie-root-port,index=2, \
        target.chassis=2,target.port=0x11, \
        address=pci:0000:00:02.1 \
        \
        --controller type=pci,model=pcie-root-port,index=3, \
        target.chassis=3,target.port=0x12, \
        address=pci:0000:00:02.2 \
        \
        --controller type=pci,model=pcie-root-port,index=4, \
        target.chassis=4,target.port=0x13, \
        address=pci:0000:00:02.3 \
        \
        --controller type=pci,model=pcie-root-port,index=5, \
        target.chassis=5,target.port=0x14, \
        address=pci:0000:00:02.4 \
        \
        --controller type=pci,model=pcie-root-port,index=6, \
        target.chassis=6,target.port=0x15, \
        address=pci:0000:00:02.5 \
        \
        --controller type=pci,model=pcie-root-port,index=7, \
        target.chassis=7,target.port=0x16, \
        address=pci:0000:00:02.6 \
        \
        --controller type=pci,model=pcie-root-port,index=8, \
        target.chassis=8,target.port=0x17, \
        address=pci:0000:00:02.7 \
        \
        --controller type=pci,model=pcie-root-port,index=9, \
        target.chassis=9,target.port=0x18, \
        address=pci:0000:00:03.0,multifunction=on \
        \
        --controller type=pci,model=pcie-root-port,index=10, \
        target.chassis=10,target.port=0x19, \
        address=pci:0000:00:03.1 \
        \
        --controller type=pci,model=pcie-root-port,index=11, \
        target.chassis=11,target.port=0x1a, \
        address=pci:0000:00:03.2 \
        \
        --controller type=pci,model=pcie-root-port,index=12, \
        target.chassis=12,target.port=0x1b, \
        address=pci:0000:00:03.3 \
        \
        --controller type=pci,model=pcie-root-port,index=13, \
        target.chassis=13,target.port=0x1c, \
        address=pci:0000:00:03.4 \
        \
        --controller type=pci,model=pcie-root-port,index=14, \
        target.chassis=14,target.port=0x1d, \
        address=pci:0000:00:03.5 \
        \
        --controller type=sata,index=0, \
        address=pci:0000:00:1f.2 \
        \
        --controller type=virtio-serial,index=0, \
        address=pci:0000:03:00.0 \
        \
        --network bridge=virbr0,model=virtio,mac=52:54:00:05:4f:06, \
        address=pci:0000:01:00.0 \
        \
        --serial pty \
        --console pty \
        \
        --channel unix,target_type=virtio,target_name=org.qemu.guest_agent.0, \
        address=virtio-serial:controller=0,bus=0,port=1 \
        \
        --channel spicevmc,target_type=virtio,target_name=com.redhat.spice.0, \
        address=virtio-serial:controller=0,bus=0,port=2 \
        \
        --input tablet,bus=usb,address=usb:0:1 \
        --input mouse,bus=ps2 \
        --input keyboard,bus=ps2 \
        \
        --graphics spice,autoport=yes,listen=address,compression=off \
        \
        --sound model=ich9,address=pci:0000:00:1b.0 \
        --audio id=1,type=spice \
        \
        --video virtio,heads=1,primary=yes,address=pci:0000:00:01.0 \
        \
        --redirdev type=spicevmc,bus=usb,port=2 \
        --redirdev type=spicevmc,bus=usb,port=3 \
        \
        --watchdog model=itco,action=reset \
        \
        --memballoon model=virtio,address=pci:0000:05:00.0 \
        \
        --rng model=virtio,backend=/dev/urandom,address=pci:0000:06:00.0 \
        \
        --on-poweroff destroy \
        --on-reboot restart \
        --on-crash destroy \
        \
        --noautoconsole
}

setup_VM_brave() {

    # Check if domain is defined using virsh dominfo (works for inactive domains)
    if ! virsh dominfo "$1" &>/dev/null; then
        echo "Domain $1 is not defined. Cleaning up leftover files..."

        # Define file paths (adjust path if needed, e.g., /etc/libvirt/qemu/, /var/lib/libvirt/images/)
        xml_file="/etc/libvirt/qemu/$1.xml"
        disk_file="$STORAGE_POOL/$1.qcow2"

        # Remove XML file if it exists
        if [ -f "$xml_file" ]; then rm -vf "$xml_file"; fi

        # Remove QCOW2 disk file if it exists
        if [ -f "$disk_file" ]; then sudo rm -vf "$disk_file"; fi
    else
        echo "Domain $1 is still defined. No files deleted."
    fi

    virt-install \
        --import \
        --disk path="${STORAGE_POOL}"/"$CDROM",device=cdrom,bus=sata \
        --os-variant fedora-unknown \
        --memory 8192 \
        --vcpus 12,placement=static \
        --disk size=40,path="${STORAGE_POOL}"/"$1".qcow2,format=qcow2,bus=virtio,discard=unmap \
        --name "$1" \
        --network bridge=virbr0,model=virtio \
        --machine q35 \
        --boot uefi,loader=/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd,loader_type=pflash,loader_secure=yes,nvram_template=/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd \
        --clock offset=localtime \
        --graphics spice \
        --features acpi=on,apic=on,vmport=off,smm=on \
        --noautoconsole \
        --print-xml | virsh define /dev/stdin

    virsh dumpxml "$1" | sudo tee "${STORAGE_POOL}/$1.xml" >/dev/null
}

install_OS() {
    # install_OS will create f<version>-<spin>_OS-installed_<date created>.qcow2
    SOURCE=$(sudo find "$STORAGE_POOL" -type f -name f"${VERSION}"-"${SPIN}"_VM-set* -printf "%P")
    SOURCE=${SOURCE%.qcow2}
    virt-clone --auto-clone --replace -o "$SOURCE" -n "$NAME"
    virsh dumpxml "$NAME" | sudo tee "${STORAGE_POOL}/${NAME}.xml" >/dev/null
}

provision_PKG() {
    # provision_PKG will create f<version>-<spin>_PKG-provisionned_<date created>.qcow2
    :
}

upgrade_OS() {
    # upgrade_OS  - f<version>-<spin>_OS-upgraded_<date created>.qcow2
    :
}

ls_xmls_w_no_qcow2() {

    sudo find "$STORAGE_POOL" -type f -name "*.xml" -exec sh -c '
    for file; do
        dir=$(dirname "$file")
        base=$(basename "$file" .xml)
        if ! [ -f "$dir/$base.qcow2" ]; then
            echo "$file"
        virsh dominfo $base || true
        # virsh domstate $base
        # virsh list --all | grep  $base
        fi
    done
' sh {} +
    read -rsn 1 -p "Press any key to continue ..."
}

clean_domain_id() {
    sudo find "${STORAGE_POOL}" -type f -name "f${VERSION}-${SPIN}*.qcow2" -printf "%P\n"
    read -rp "Enter prefix for prefix*.qcow2 files to be removed: "
    sudo find "${STORAGE_POOL}" -maxdepth 1 -name "${REPLY}*.qcow2" -print0 | while IFS= read -r -d '' disk; do
        domain=$(basename "$disk" .qcow2)
        virsh list --all | grep -q " $domain " || sudo rm -v "$disk"
    done
}

# Main
while true; do
    status
    read -n 1 -rsp "
    1. setup_VM
    2. install_OS
    3. provision_PKG
    4. upgrade_OS
    5. ls_xmls_w_no_qcow2
    6. clean_domain_id
    q  exit
    "

    case $REPLY in
    1)
        name VM-set
        echo -e "creating ${NAME} ...\n"
        setup_VM_brave "$NAME"
        ;;
    2)
        name OS-installed
        echo -e "creating ${NAME} ...\n"
        ;;

    5) ls_xmls_w_no_qcow2 ;;

    6) clean_domain_id ;;
    q) echo -e 'Exiting ...\n' && exit 0 ;;
    *) echo -e 'Not implemented yet, exiting ...\n' && exit 1 ;;
    esac
done
