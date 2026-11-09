# OpenStack private cloud with Kolla-Ansible

This is a lab I did during my Master's at ESGI Paris (Systems, Networks & Cloud Computing), together with a classmate. The goal was to deploy a multi-node OpenStack cloud ourselves with Kolla-Ansible, then actually use it: create projects and users, build networks, launch instances, attach volumes and play with availability zones and host aggregates.

Everything below is what we really ran. Passwords and a few values are replaced with placeholders.

## The setup

We had 4 Ubuntu nodes:

| Node | Role |
|---|---|
| controller01 | control plane, networking and monitoring |
| compute01 | hypervisor (KVM) |
| compute02 | hypervisor (KVM) |
| stockage01 | block storage (Cinder on LVM) |

Each node had three network interfaces:

- `eth0` for management and the OpenStack APIs
- `eth1` for the Neutron tunnels between nodes
- `eth2` as the external network for Neutron

Services we enabled: Keystone, Glance, Nova, Neutron, Cinder, Swift and Horizon. We turned HAProxy off since we only had one controller.

## Deployment

### Preparing the nodes

On every node we installed the dependencies, created a `kolla` user with passwordless sudo and set up SSH keys from the controller so Ansible could reach everything:

```bash
sudo apt update
sudo apt install python3-dev libffi-dev gcc libssl-dev python3-venv docker.io

sudo useradd -m -s /bin/bash kolla
echo "kolla ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/kolla

# from the controller
ssh-keygen -t rsa
ssh-copy-id kolla@<node_ip>
```

On the storage node we created the volume group Cinder uses:

```bash
sudo pvcreate /dev/sdb
sudo vgcreate cinder-volumes /dev/sdb
```

### Installing Kolla-Ansible

```bash
python3 -m venv /home/kolla/kolla-ansible/venv
source /home/kolla/kolla-ansible/venv/bin/activate
pip install git+https://opendev.org/openstack/kolla-ansible@master
kolla-ansible install-deps
```

### Inventory

We started from the `multinode` example inventory and set the roles for our nodes:

```ini
[control]
controller01 ansible_host=192.168.200.100 ansible_user=kolla ansible_become=true

[network]
controller01

[compute]
compute01 ansible_host=192.168.200.120 ansible_user=kolla ansible_become=true
compute02 ansible_host=192.168.200.121 ansible_user=kolla ansible_become=true

[monitoring]
controller01

[storage]
stockage01 ansible_host=192.168.200.200 ansible_user=kolla ansible_become=true
```

### globals.yml

```yaml
kolla_base_distro: "ubuntu"
kolla_internal_vip_address: "<unused IP in the management range>"

network_interface: "eth0"
api_interface: "eth0"
tunnel_interface: "eth1"
neutron_external_interface: "eth2"

enable_haproxy: "no"
enable_proxysql: "no"

enable_keystone: "yes"
enable_glance: "yes"
enable_nova: "yes"
enable_neutron: "yes"
enable_cinder: "yes"
enable_swift: "yes"
enable_horizon: "yes"

enable_cinder_backend_lvm: "yes"
cinder_volume_group: "cinder-volumes"
```

### Running the deployment

```bash
kolla-ansible bootstrap-servers -i /etc/kolla/multinode
kolla-ansible prechecks -i /etc/kolla/multinode
kolla-ansible pull -i /etc/kolla/multinode
kolla-ansible deploy -i /etc/kolla/multinode
```

After that we installed the CLI, sourced the admin credentials and logged into Horizon with the admin password generated in `passwords.yml`:

```bash
pip install python-openstackclient
source admin-openrc.sh
```

## Using the cloud

### Projects, users and groups

```bash
openstack project create esgi

openstack user create esgi-admin --password <password>
openstack role add --project esgi --user esgi-admin admin

openstack user create user1 --password <password>
openstack user create user2 --password <password>
openstack group create esgi_group
openstack group add user esgi_group user1
openstack group add user esgi_group user2

openstack role assignment list --project esgi --names
```

### Networks and routing

Two private networks connected through a router:

```bash
openstack network create net-esgi-1 --project esgi
openstack subnet create subnet-esgi-1 --network net-esgi-1 \
  --subnet-range 10.10.1.0/24 --gateway 10.10.1.1 --dns-nameserver 8.8.8.8

openstack network create net-esgi-2 --project esgi
openstack subnet create subnet-esgi-2 --network net-esgi-2 \
  --subnet-range 10.10.2.0/24 --gateway 10.10.2.1 --dns-nameserver 8.8.8.8

openstack router create router-esgi --project esgi
openstack router add subnet router-esgi subnet-esgi-1
openstack router add subnet router-esgi subnet-esgi-2
```

### Instances, volumes and SSH

```bash
openstack image create "cirros" --file cirros-0.6.2-x86_64-disk.img \
  --disk-format qcow2 --container-format bare --public
openstack flavor create m1.tiny --ram 256 --disk 1 --vcpus 1
openstack keypair create esgi-key > esgi-key.pem

openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default

openstack server create vm-esgi-1 --image cirros --flavor m1.tiny \
  --network net-esgi-1 --key-name esgi-key

openstack volume create --size 1 volume-esgi-1
openstack server add volume vm-esgi-1 volume-esgi-1
```

### Availability zones and host aggregates

```bash
openstack availability zone list

# pin an instance to a specific hypervisor
openstack server create vm-esgi-az --image cirros --flavor m1.tiny \
  --network net-esgi-1 --key-name esgi-key --availability-zone nova:compute01

# group hosts by hardware, e.g. SSD
openstack aggregate create aggregate-ssd
openstack aggregate add host aggregate-ssd compute01
openstack aggregate set --property disk=ssd aggregate-ssd
```

## What I took away from it

The deployment itself is mostly waiting for Kolla to pull and start containers. The hard part is getting the networking right before you start, because almost every problem we hit came back to interfaces, IPs or the external network.

It also made the cloud a lot less magic for me. When you create a VM in AWS or GCP you just click a button. Here you see every step: Keystone checks the token, the Nova scheduler picks a hypervisor, Glance hands over the image, Neutron sets up the ports and security groups, Cinder attaches the volume, and nova-compute finally starts the VM on KVM. Once you've debugged that chain yourself, public clouds make a lot more sense.

Besides the hands-on part, the lab covered how OpenStack is built: the main services and their endpoints, ML2/OVS vs ML2/OVN for Neutron, storage options for Nova, and how scheduling filters work with availability zones and aggregates.
