# 🏗️ OpenStack Private Cloud — Kolla-Ansible

> Deployment of a fully functional private cloud using OpenStack via Kolla-Ansible on bare-metal / virtual infrastructure.

---

## 📋 Overview

This repository documents the deployment of a **private cloud infrastructure** using OpenStack, orchestrated with **Kolla-Ansible** — the official OpenStack deployment tool based on Docker containers.

Built as part of my Master's degree in Systems, Networking & Cloud Computing at ESGI Paris.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│               OpenStack Private Cloud            │
│                                                 │
│  ┌─────────────┐        ┌─────────────────────┐ │
│  │  Controller │        │    Compute Node     │ │
│  │             │        │                     │ │
│  │  - Keystone │◄──────►│  - Nova (instances) │ │
│  │  - Glance   │        │  - Neutron Agent    │ │
│  │  - Horizon  │        │  - Cinder Volume    │ │
│  │  - Neutron  │        └─────────────────────┘ │
│  └─────────────┘                                │
│         │                                       │
│  ┌──────▼──────┐                                │
│  │   Storage   │                                │
│  │  (Cinder)   │                                │
│  └─────────────┘                                │
└─────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Deployment tool | Kolla-Ansible |
| Containerization | Docker |
| OS | Ubuntu 22.04 LTS |
| Compute | Nova |
| Networking | Neutron (VXLAN/FLAT) |
| Storage | Cinder (LVM) |
| Identity | Keystone |
| Image service | Glance |
| Dashboard | Horizon |
| Automation | Ansible |

---

## 📁 Repository Structure

```
openstack-kolla-private-cloud/
├── inventory/
│   ├── multinode              # Ansible inventory (controller + compute)
│   └── passwords.yml          # Generated service passwords (gitignored)
├── config/
│   ├── globals.yml            # Main Kolla-Ansible configuration
│   └── neutron/
│       └── ml2_conf.ini       # Neutron ML2 plugin config
├── scripts/
│   ├── install-dependencies.sh  # Bootstrap script
│   ├── pre-deploy.sh            # Pre-deployment checks
│   └── post-deploy.sh           # Post-deployment setup
├── docs/
│   ├── architecture.md        # Detailed architecture documentation
│   ├── network-setup.md       # Network configuration guide
│   └── troubleshooting.md     # Common issues and fixes
└── README.md
```

---

## 🚀 Deployment Steps

### 1. Prerequisites

```bash
# Install Kolla-Ansible
pip install kolla-ansible

# Install Ansible dependencies
kolla-ansible install-deps
```

### 2. Configure Inventory

```ini
# inventory/multinode
[control]
controller01 ansible_host=192.168.1.10

[compute]
compute01 ansible_host=192.168.1.11

[storage]
storage01 ansible_host=192.168.1.12
```

### 3. Configure globals.yml

```yaml
# config/globals.yml
kolla_base_distro: "ubuntu"
kolla_install_type: "source"
openstack_release: "2023.2"

network_interface: "eth0"
neutron_external_interface: "eth1"

enable_cinder: "yes"
enable_horizon: "yes"
enable_neutron: "yes"
```

### 4. Deploy

```bash
# Bootstrap servers
kolla-ansible -i inventory/multinode bootstrap-servers

# Pre-deployment checks
kolla-ansible -i inventory/multinode prechecks

# Deploy OpenStack
kolla-ansible -i inventory/multinode deploy

# Post-deploy configuration
kolla-ansible -i inventory/multinode post-deploy
```

---

## ⚙️ OpenStack Services Deployed

| Service | Role | Status |
|---------|------|--------|
| Keystone | Identity & Auth | ✅ |
| Glance | Image management | ✅ |
| Nova | Compute (VM instances) | ✅ |
| Neutron | Virtual networking | ✅ |
| Cinder | Block storage | ✅ |
| Horizon | Web dashboard | ✅ |

---

## 🌐 Network Configuration

- **Provider network:** FLAT — direct access to physical network
- **Tenant networks:** VXLAN overlay for VM-to-VM isolation
- **Floating IPs:** External access to instances
- **Security groups:** Firewall rules per instance

```bash
# Create external network
openstack network create --external --provider-network-type flat \
  --provider-physical-network physnet1 external-net

# Create subnet
openstack subnet create --network external-net \
  --subnet-range 192.168.100.0/24 \
  --gateway 192.168.100.1 external-subnet
```

---

## 💾 Storage — Cinder (LVM)

```bash
# Create volume
openstack volume create --size 10 my-volume

# Attach to instance
openstack server add volume my-instance my-volume
```

---

## 🖥️ Horizon Dashboard

After deployment, the Horizon web dashboard is accessible at:

```
http://<controller-ip>/
Username: admin
Password: (generated in passwords.yml)
```

---

## 📝 Key Learnings

- Kolla-Ansible abstracts OpenStack complexity into Docker containers, making deployment reproducible
- Neutron network configuration is the most complex part — VXLAN vs FLAT vs VLAN requires careful planning
- Cinder LVM backend requires dedicated disk/partition on storage nodes
- Always run `prechecks` before `deploy` to catch configuration issues early

---

## 🎓 Context

This project was developed as part of the **Master's Degree in Systems, Networking & Cloud Computing** at **ESGI Paris** (2024–2026), in the DevOps & Cloud specialization.

**Author:** Konrad Sagan  
**LinkedIn:** [linkedin.com/in/justkonrad](https://linkedin.com/in/justkonrad)  
**GitHub:** [github.com/JustKonrad](https://github.com/JustKonrad)
