#!/usr/bin/env bash
# script to run immmediately after Fedora install. A copy should be on the usb key from where it should be run.

set -euo pipefail
set +x

# set up dnf so that optimum
if [[ ! $(sed -n '$p' /etc/dnf/dnf.conf) == 'max_parallel_downloads=10' ]]; then
    cat <<. | sudo tee -a /etc/dnf/dnf.conf
fastestmirror=1 # check if that is still needed, or in this form with Fedora install files
max_parallel_downloads=10
.
fi

# install git and ansible
sudo dnf update -y # maybe don't need it
sudo dnf install git gh ansible -y

# will install Astrill if needed and then exit to set it up, if not, will pursue
rpm -q astrill >/dev/null || (
    sudo rpm -i astrill-setup-linux64.rpm && echo 'Exiting to setup Astrill ...' && exit 0
)

read -rsn 1 -p $'\nCtrl-C to set VPN on, or press any key to continue ...\n'

# under VPN clone public directories
mkdir -p /home/perubu/Documents/Github && cd "$_"

for repo in \
    ahjun001 \
    0.template \
    1.fedora_install_n_settings \
    2.1.ansible \
    2.1.linux \
    2.1.gh \
    2.1.vim \
    2.2.nvim \
    2.2.vscode \
    2.2.bash \
    2.2.shellspec \
    2.2.ffmpeg \
    2.2.asciidoctor \
    2.3.podman; do
    if [ ! -d "$repo" ]; then git clone https://github.com/ahjun001/"$repo"; fi
done

cd /home/perubu/Documents/Github/1.fedora_install_n_settings/4.Projects/post_install/ansible

ansible-playbook -Ki inventories/hosts playbook.yml

gh auth setup-git