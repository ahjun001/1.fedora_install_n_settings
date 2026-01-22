#!/usr/bin/env bash
# config.sh  single, sourced configuration file (e.g., config.sh) that exports all shared environment variables.
# This avoids duplication and ensures consistency.
# This file is not executed directly — it’s sourced by other scripts.
set -xeuo pipefail

export STORAGE_POOL=/var/lib/libvirt/images
export SPIN=kde # choose from kde kinos workstation
export VERSION=42
DATE=$(date '+%Y-%m-%d')
export DATE