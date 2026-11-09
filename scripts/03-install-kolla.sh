#!/usr/bin/env bash
# Run on the CONTROLLER as the kolla user.
# Installs kolla-ansible in a virtualenv and puts the config in /etc/kolla.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV=/home/kolla/kolla-ansible/venv

# SSH key used by Ansible to reach the other nodes
[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

python3 -m venv "$VENV"
source "$VENV/bin/activate"
pip install -U pip
pip install git+https://opendev.org/openstack/kolla-ansible@master
kolla-ansible install-deps

sudo mkdir -p /etc/kolla
sudo chown kolla:kolla /etc/kolla

# Our config
cp "$REPO_DIR/config/globals.yml" /etc/kolla/globals.yml

# Inventory: start from the example shipped with kolla-ansible, then replace the top groups
cp "$VENV/share/kolla-ansible/ansible/inventory/multinode" /etc/kolla/multinode
echo ">>> Now edit /etc/kolla/multinode and replace the [control], [network], [compute],"
echo ">>> [monitoring] and [storage] groups with the ones in inventory/multinode."

# Generate a random password for every service
cp "$VENV/share/kolla-ansible/etc_examples/kolla/passwords.yml" /etc/kolla/passwords.yml
kolla-genpwd -p /etc/kolla/passwords.yml
