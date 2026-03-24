#!/usr/bin/env bash
# _config.sh  single, sourced configuration file (e.g., config.sh) that exports all shared environment variables.
# This avoids duplication and ensures consistency.
# This file is not executed directly — it’s sourced by other scripts.
set -euo pipefail

# setting working directories
export STORAGE_POOL=/var/lib/libvirt/images
export QEMU_CONF_DIR=/etc/libvirt/qemu

DISTRO=fedora # fedora | lmint
# setting CDROM
case $DISTRO in
fedora)
    export OS_VARIANT=fedora-unknown
    export SPIN=kinos
    VERSION=43
    case $SPIN in
    kde)
        case $VERSION in
        42) export CDROM=Fedora-KDE-Desktop-Live-42-1.1.x86_64.iso ;;
        43) export CDROM=Fedora-KDE-Desktop-Live-43-1.6.x86_64.iso ;;
        esac
        ;;
    workstation)
        export CDROM="Fedora-Workstation-Live-${VERSION}-1.6.x86_64.iso"
        ;;
    kinos)
        case $VERSION in
        42) export CDROM="Fedora-Kinoite-ostree-x86_64-42-1.1.iso" ;;
        43) export CDROM="Fedora-Kinoite-ostree-x86_64-43-1.6.iso" ;;
        esac
        ;;
    *) echo -e 'Naming convention not respected, exiting ...\n' >&2 && exit 1 ;;
    esac
    ;;
lmint)
    export OS_VARIANT=debian13
    export CDROM="lmde-7-cinnamon-64bit.iso"
    ;;
*) echo -e 'Unknown distro, exiting ...\n' >&2 && exit 1 ;;
esac

# DATE=$(date '+%Y-%m-%d')
# export DATE

# Stage progression order (from base to final)
declare -a STAGES=(
    "VM-set"
    "updating-OS-WIP"
    "OS-updated"
    "provisionning-Core-WIP"
    "Core-provisionned"
    "provisionning-Host-sup-WIP"
    "Host-sup-provisionned"
    "OS-upgraded"
)
export STAGES

# Function to build filename
build_filename() {
    local stage="$1"
    case $DISTRO in
    fedora) echo "f${VERSION}-${SPIN}_${stage}" ;;
    lmint) echo "lmde-7-cin_${stage}" ;;
    *) echo "unknown-distro_${stage}" >&2 && return 1 ;;
    esac
}
