#!/usr/bin/env bash
# Run on EVERY node (controller, compute, storage).
# Installs the dependencies and creates the "kolla" user Ansible connects with.
set -euo pipefail

sudo apt update
sudo apt install -y python3-dev libffi-dev gcc libssl-dev python3-venv docker.io

if ! id kolla >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash kolla
fi

# Passwordless sudo so Ansible can become root
echo "kolla ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/kolla >/dev/null
sudo chmod 440 /etc/sudoers.d/kolla

echo "Node ready. From the controller, copy the SSH key with: ssh-copy-id kolla@<node_ip>"
