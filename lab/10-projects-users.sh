#!/usr/bin/env bash
# Projects, users, groups and roles.
# Usage: source /etc/kolla/admin-openrc.sh && USER_PASSWORD='...' ./lab/10-projects-users.sh
set -euo pipefail
: "${USER_PASSWORD:?Set USER_PASSWORD first}"

openstack project create esgi

# A project admin
openstack user create esg_5 --password "$USER_PASSWORD"
openstack role add --project esgi --user esg_5 admin

# Two regular users managed through a group
openstack user create user1 --password "$USER_PASSWORD"
openstack user create user2 --password "$USER_PASSWORD"
openstack group create esgi_group
openstack group add user esgi_group user1
openstack group add user esgi_group user2
openstack role add --group esgi_group --project esgi member

openstack user list
openstack group list
openstack role assignment list --project esgi --names
