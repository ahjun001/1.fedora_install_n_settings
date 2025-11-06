#!/usr/bin/env bash
# ./create_new_role.sh

set -euo pipefail

Usage() {
    cat <<.

usage: ${0##*/} <new_role>

.
}

[[ $# == 1 ]] || {
    Usage
    exit
}

ARG=roles/"$1"/tasks

if [[ -d $ARG ]]; then
    echo "$ARG"/ already exists
    echo exiting...
    exit
fi

mkdir -p "$ARG"
cat <<. >>"$ARG"/main.yml
---
# ./roles/$1/tasks/main.yml
# task file for $1

.
