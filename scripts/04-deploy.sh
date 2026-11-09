#!/usr/bin/env bash
# Run on the CONTROLLER as the kolla user, after 03-install-kolla.sh.
set -euo pipefail

source /home/kolla/kolla-ansible/venv/bin/activate
INV=/etc/kolla/multinode

ansible -i "$INV" all -m ping          # every node must answer before going further
kolla-ansible bootstrap-servers -i "$INV"
kolla-ansible prechecks -i "$INV"
kolla-ansible pull -i "$INV"
kolla-ansible deploy -i "$INV"
