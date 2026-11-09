#!/usr/bin/env bash
# Image, flavor, keypair, security group rules, one instance and an attached volume.
set -euo pipefail

CIRROS=cirros-0.6.2-x86_64-disk.img
[ -f "$CIRROS" ] || wget "https://github.com/cirros-dev/cirros/releases/download/0.6.2/$CIRROS"

openstack image create cirros \
  --file "$CIRROS" \
  --disk-format qcow2 \
  --container-format bare \
  --public

openstack flavor create m1.tiny --ram 256 --disk 1 --vcpus 1
openstack keypair create esgi-key > esgi-key.pem
chmod 600 esgi-key.pem

# Allow ping and SSH in the default security group
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default

openstack hypervisor list
openstack server create vm-esgi-1 \
  --image cirros \
  --flavor m1.tiny \
  --network net-esgi-1 \
  --key-name esgi-key \
  --tag tp9 \
  --property environnement=lab \
  --wait

openstack volume create --size 1 volume-esgi-1
openstack server add volume vm-esgi-1 volume-esgi-1   # shows up as /dev/vdb in the VM

openstack server show vm-esgi-1
openstack volume list
