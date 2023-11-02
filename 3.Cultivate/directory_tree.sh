#!/usr/bin/env bash

set -euo pipefail

mkdir -p new_project/
cd new_project || exit 1

cat <<. >Vagrantfile
# Vagrantfile
# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure('2') do |config|
  config.vm.box = 'hashicorp/bionic64'
end
.

mkdir -p ansible/
cd ansible || exit 1
touch playbook.yml
cat <<. >playbook.yml
---
# playbook.yml
- hosts: all
  become: true
  become_method: sudo
  roles:
    - "role 1"
    - "role 2"
.

mkdir -p roles/
cd roles || exit 1
for i in 1 2; do
    mkdir -p role$i/{files,handlers,meta,templates,tasks,vars,defaults}
done
cd ..
mkdir -p inventories
cd inventories || exit 1
mkdir -p {production,staging}/group_vars
cat <<. >staging/hosts
# hosts

[fedora38]
vmhost ansible_host=192.168.121.36 ansible_user=vagrant ansible_private_key_file=.vagrant/machines/fedora38/libvirt/private_key
.
cp staging/hosts production/

cd ../..
mkdir -p molecule
cd molecule
mkdir -p {default,another_scenario}/tests
touch {default,another_scenario}/{molecule.yml,playbook.yml}
cd ../..
echo END
