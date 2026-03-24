#!/bin/bash
# Helper script for quick VM clone/convert operations
# Usage:
#   ./scripts/vm_clone_helper.sh thin-clone <backing-img> <dest-name> [pool]
#   ./scripts/vm_clone_helper.sh convert-full <thin-img> <dest-name> [pool]
#   ./scripts/vm_clone_helper.sh sysprep <domain-name> <image-path>

set -e

ACTION="${1:-}"
BACKING_IMG="${2:-}"
DEST_NAME="${3:-}"
POOL="${4:-default}"
IMAGE_PATH="/var/lib/libvirt/images"

function usage() {
  cat << 'EOF'
Usage: vm_clone_helper.sh <action> [options]

Actions:
  thin-clone <backing-img> <dest-name> [pool]
    Create a thin clone (backed by backing-img) in the specified pool.
    Example: ./vm_clone_helper.sh thin-clone fedora43-base.qcow2 fedora43-kde.setup-20251112.qcow2

  convert-full <thin-img> <dest-name> [pool]
    Convert a thin clone to a full independent image.
    Example: ./vm_clone_helper.sh convert-full fedora43-kde.setup-20251112.qcow2 fedora43-kde.installed-20251112.qcow2

  sysprep <domain-name> <image-path>
    Shutdown domain and run virt-sysprep to clear machine-specific state.
    Example: ./vm_clone_helper.sh sysprep fedora43-kde /var/lib/libvirt/images/fedora43-kde.qcow2

EOF
  exit 1
}

function thin_clone() {
  local backing="$1"
  local dest="$2"
  # pool parameter not used (inferred from IMAGE_PATH)
  
  if [ -z "$backing" ] || [ -z "$dest" ]; then
    echo "Error: thin-clone requires <backing-img> and <dest-name>"
    usage
  fi
  
  local backing_path="${IMAGE_PATH}/${backing}"
  local dest_path="${IMAGE_PATH}/${dest}"
  
  if [ ! -f "$backing_path" ]; then
    echo "Error: backing image not found: $backing_path"
    exit 1
  fi
  
  echo "Creating thin clone:"
  echo "  Backing: $backing_path"
  echo "  Destination: $dest_path"
  
  qemu-img create -f qcow2 -b "$backing_path" "$dest_path"
  echo "✓ Thin clone created: $dest_path"
}

function convert_full() {
  local thin="$1"
  local dest="$2"
  # pool parameter not used (inferred from IMAGE_PATH)
  
  if [ -z "$thin" ] || [ -z "$dest" ]; then
    echo "Error: convert-full requires <thin-img> and <dest-name>"
    usage
  fi
  
  local thin_path="${IMAGE_PATH}/${thin}"
  local dest_path="${IMAGE_PATH}/${dest}"
  
  if [ ! -f "$thin_path" ]; then
    echo "Error: thin image not found: $thin_path"
    exit 1
  fi
  
  echo "Converting thin clone to full image:"
  echo "  Source: $thin_path"
  echo "  Destination: $dest_path"
  
  qemu-img convert -O qcow2 "$thin_path" "$dest_path"
  echo "✓ Conversion complete: $dest_path"
  echo ""
  echo "Next steps:"
  echo "  1. Update the domain XML to point to the new image"
  echo "  2. Optionally delete the thin clone: rm $thin_path"
}

function sysprep() {
  local domain="$1"
  local image_path="$2"
  
  if [ -z "$domain" ] || [ -z "$image_path" ]; then
    echo "Error: sysprep requires <domain-name> and <image-path>"
    usage
  fi
  
  if [ ! -f "$image_path" ]; then
    echo "Error: image not found: $image_path"
    exit 1
  fi
  
  echo "Preparing domain $domain for sysprep..."
  
  # Check if domain is running
  if virsh domstate "$domain" 2>/dev/null | grep -q "running"; then
    echo "Domain is running, attempting graceful shutdown..."
    virsh shutdown "$domain" || true
    
    # Wait up to 30 seconds for shutdown
    for _ in {1..30}; do
      if ! virsh domstate "$domain" 2>/dev/null | grep -q "running"; then
        echo "✓ Domain shutdown successfully"
        break
      fi
      sleep 1
    done
    
    # If still running, force shutdown
    if virsh domstate "$domain" 2>/dev/null | grep -q "running"; then
      echo "Domain still running, forcing shutdown..."
      virsh destroy "$domain" || true
    fi
  fi
  
  echo "Running virt-sysprep on $image_path..."
  virt-sysprep -a "$image_path" \
    --enable=dhcp-client-state \
    --enable=logfiles \
    --enable=machine-id \
    --enable=net-hwaddr \
    --enable=ssh-hostkeys \
    --enable=ssh-userdir \
    --enable=tmp-files \
    --enable=customize
  
  echo "✓ Sysprep complete: $image_path"
}

case "$ACTION" in
  thin-clone)
    thin_clone "$BACKING_IMG" "$DEST_NAME" "$POOL"
    ;;
  convert-full)
    convert_full "$BACKING_IMG" "$DEST_NAME" "$POOL"
    ;;
  sysprep)
    sysprep "$BACKING_IMG" "$DEST_NAME"
    ;;
  *)
    usage
    ;;
esac
