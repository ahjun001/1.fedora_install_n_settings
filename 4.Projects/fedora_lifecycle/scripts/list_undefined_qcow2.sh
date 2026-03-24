#!/usr/bin/env bash
# list_unused_iso.sh
# in the VM lifecyle of creating, installing the OS, updating, provisionning, upgrapding to next OS version, many .qcow2
# files are not used for day to day tasks.
# While it is good to keep them, just in case, they should be undefine to not clutter the Virtual Machine Manager.
# This util list them so that they can be removed when not useful any longer.
set -euo pipefail

# source _config.sh to get STORAGE_POOL
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/config.sh"


USED_DISKS=$(virsh list --all --name | xargs -I {} virsh dumpxml {} 2>/dev/null | grep -oP '<source file=[^>]*\.qcow2[^>]*>' | sed -r 's/.*file=['\''"'"'"']([^'\''"'"'"']*)['\''"'"'"'].*/\1/')

sudo find "$STORAGE_POOL" -type f -name "*.qcow2" | while read -r disk; do
    if ! echo "$USED_DISKS" | grep -Fxq "$disk"; then
        echo "Orphaned: $disk"
    fi
done
