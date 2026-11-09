#!/usr/bin/env bash
# Run on the STORAGE node only.
# Creates the LVM volume group that Cinder uses for block volumes.
set -euo pipefail

DISK="${1:-/dev/sdb}"

sudo pvcreate "$DISK"
sudo vgcreate cinder-volumes "$DISK"
sudo vgs cinder-volumes
