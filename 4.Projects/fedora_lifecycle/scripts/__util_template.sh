#!/usr/bin/env bash
# util_template.sh
set -euo pipefail

# Ensure robust sourcing by locating config.sh relative to the script:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_config.sh"
