#!/usr/bin/env bash
# Run on the CONTROLLER once the deployment is done.
set -euo pipefail

source /home/kolla/kolla-ansible/venv/bin/activate

pip install python-openstackclient
kolla-ansible post-deploy -i /etc/kolla/multinode   # writes /etc/kolla/admin-openrc.sh

source /etc/kolla/admin-openrc.sh
openstack service list
openstack compute service list
openstack network agent list

echo
echo "Horizon: http://<controller_ip>  (user: admin)"
echo "Admin password: grep keystone_admin_password /etc/kolla/passwords.yml"
