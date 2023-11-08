#!/usr/bin/env bash
# script to run immmediately after Fedora install. A copy should be on a usb key from where it should be run.

set -euo pipefail
set -x

# will install Astrill if needed and then exit to set it up, if not, will pursue
rpm -q astrill >/dev/null || {
    rpm -i astrill-setup-linux64.rpm && echo 'Exiting to setup Astrill ...' && exit 0
}

mkdir -p /home/perubu/Documents/Github && cd "$_"

for repo in \
    1.fedora_install_n_settings \
    2.1.linux \
    2.1.vim \
    2.2.nvim \
    2.3.podman; do
    if [ ! -d "$repo" ]; then git clone https://github.com/ahjun001/"$repo"; fi
done

: && exit
for repo in \
    ahjun001 \
    0.template \
    1.fedora_install_n_settings \
    2.1.linux \
    2.1.gh \
    2.2.vim \
    2.2.nvim \
    2.2.vscode \
    2.2.bash \
    2.2.shellspec \
    2.2.ffmpeg \
    2.2.asciidoctor \
    2.3.podman; do
    if [ ! -d "$repo" ]; then git clone "$repo"; fi
done
