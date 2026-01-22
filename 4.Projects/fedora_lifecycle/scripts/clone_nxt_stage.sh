#!/usr/bin/env bash
# util_template.sh
set -euo pipefail

# Ensure robust sourcing by locating config.sh relative to the script:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_config.sh"

main() {
    # Find the most advanced existing stage
    CURRENT_STAGE=""
    CURRENT_FILE=""

    for stage in "${STAGES[@]}"; do
        fdomain=$(build_filename "$stage")
        fpath="${STORAGE_POOL}/${fdomain}.qcow2"
        if [ -f "$fpath" ]; then
            CURRENT_STAGE=$stage
            CURRENT_DOMAIN=$fdomain
            CURRENT_FILE=$fpath
        else
            break # Stop at first missing stage
        fi
    done

    if [ -z "$CURRENT_STAGE" ]; then
        echo "Error: No initial VM image found for distro $DISTRO."
        echo "Expected base image: $(build_filename 'VM-set')"
        exit 1
    fi

    # Determine NEXT_STAGE, and set NEXT_FILE, NEXT_DOMAIN
    NEXT_STAGE=""
    for i in "${!STAGES[@]}"; do
        if [ "${STAGES[$i]}" = "$CURRENT_STAGE" ]; then
            if [ $((i + 1)) -ge ${#STAGES[@]} ]; then
                echo "All stages are already complete for $(build_filename "")."
                exit 0
            fi
            NEXT_STAGE="${STAGES[$((i + 1))]}"
            break
        fi
    done

    if [ -z "$NEXT_STAGE" ]; then
        echo "Error: Could not determine next stage after ${CURRENT_STAGE}." exit 1
    fi

    NEXT_DOMAIN=$(build_filename "$NEXT_STAGE")
    NEXT_FILE="${STORAGE_POOL}/${NEXT_DOMAIN}.qcow2"

    echo "Progressing VM:"
    echo "  From: $CURRENT_FILE"
    echo "  To:   $NEXT_FILE"
    echo

    # Confirm action
    read -p "Proceed with cloning and sysprep? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 1
    fi

    # 1. Shut down the source VM
    if virsh list --state-running | grep -q "$CURRENT_DOMAIN"; then
        sudo virsh shutdown "$CURRENT_DOMAIN"
    fi

    # 2. Clone the original VM (preserves the working copy)
    sudo virt-clone --original="$CURRENT_DOMAIN" \
        --name="$NEXT_DOMAIN" \
        --file="$NEXT_FILE"

    # 3. Run virt-sysprep on the *clone* to reset unique data
    if ! [[ $DISTRO == 'fedora' && $SPIN == 'kinos' ]]; then
        set -x
        sudo virt-sysprep -d "$NEXT_DOMAIN"
        set +x
    fi

    # set -x
    # # Clone using qemu-img (copy-on-write not used here for independence)
    # echo "Cloning image..."
    # if ! sudo qemu-img create -f qcow2 -b "$CURRENT_FILE" -F qcow2 "$NEXT_FILE"; then
    #     echo "Error: Failed to clone image."
    #     exit 1
    # fi

    # # Run virt-sysprep to remove host-specific data
    # echo "Running virt-sysprep to ensure uniqueness..."
    # if ! virt-sysprep \
    #     --quiet \
    #     --format qcow2 \
    #     -a "$NEXT_FILE" \
    #     --enable ssh-hostkeys,machine-id,udev-persistent-net,net-hostname,net-hwaddr,tmp-files,logfiles,rpm-db \
    #     ; then
    #     echo "Error: virt-sysprep failed. You may need to install libguestfs-tools."
    #     rm -f "$NEXT_FILE"
    #     exit 1
    # fi

    echo
    echo Listing files:
    sudo find "${STORAGE_POOL}" -type f -name "$NEXT_DOMAIN".qcow2 -exec ls -l {} \;
    sudo find "${QEMU_CONF_DIR}" -type f -name "$NEXT_DOMAIN".xml -exec ls -l {} \;
    echo "Success! VM advanced to next stage."
}

# main
main
