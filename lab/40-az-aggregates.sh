#!/usr/bin/env bash
# Availability zones, pinning an instance to a host, and host aggregates.
set -euo pipefail

openstack availability zone list

# Let the scheduler pick a host inside the "nova" zone
openstack server create vm-esgi-az \
  --image cirros --flavor m1.tiny --network net-esgi-1 \
  --key-name esgi-key --availability-zone nova

# Force a specific hypervisor with zone:host
openstack server create vm-esgi-az-compute01 \
  --image cirros --flavor m1.tiny --network net-esgi-1 \
  --key-name esgi-key --availability-zone nova:compute01

openstack server show vm-esgi-az-compute01 -c OS-EXT-AZ:availability_zone -c OS-EXT-SRV-ATTR:host

# Group hosts by hardware (here: SSD) with metadata the scheduler can use
openstack aggregate create aggregate-ssd
openstack aggregate add host aggregate-ssd compute01
openstack aggregate set --property disk=ssd aggregate-ssd
openstack aggregate show aggregate-ssd

# Which filters is the scheduler using?
sudo docker exec -it nova_scheduler grep -A5 "\[filter_scheduler\]" /etc/nova/nova.conf
