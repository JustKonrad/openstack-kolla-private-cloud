#!/usr/bin/env bash
# Two private VXLAN networks in the esgi project, connected by a router.
set -euo pipefail

openstack network create net-esgi-1 --project esgi
openstack subnet create subnet-esgi-1 \
  --network net-esgi-1 \
  --subnet-range 10.10.1.0/24 \
  --gateway 10.10.1.1 \
  --dns-nameserver 8.8.8.8

openstack network create net-esgi-2 --project esgi
openstack subnet create subnet-esgi-2 \
  --network net-esgi-2 \
  --subnet-range 10.10.2.0/24 \
  --gateway 10.10.2.1 \
  --dns-nameserver 8.8.8.8

openstack router create router-esgi --project esgi
openstack router add subnet router-esgi subnet-esgi-1
openstack router add subnet router-esgi subnet-esgi-2

openstack network list
openstack subnet list
openstack router show router-esgi
