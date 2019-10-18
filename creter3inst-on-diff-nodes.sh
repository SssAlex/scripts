#!/bin/bash
#rewrite to heat template
#rewrite usege sed/awk

# touch ./creter3inst-on-diff-nodes.sh
# chmod +x ./creter3inst-on-diff-nodes.sh

set -ex
# set -e --- Exit immediately if a command exits with a non-zero status.
# set -x --- Print commands and their arguments as they are executed.

source ~/osclient/bin/activate

export OS_CACERT=/etc/ssl/certs/
export OS_CLOUD=openstack_helm

IMAGE_URL="http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img"
UID_PRIFIX="userTest-$(tr -cd '[:digit:]' < /dev/urandom | fold -w8 | head -n1)"
SUBNET_RANGE="172.30.100.0/24"

OS_FLAVOR=$UID_PRIFIX-testFlavor
OS_NETWORK=$UID_PRIFIX-testNetwork
OS_SUBNET=$UID_PRIFIX-testSubnet
OS_ROUTER=$UID_PRIFIX-testRouter
OS_SECURITYGROUP=$UID_PRIFIX-testSecurityGroup
OS_VMInstance=$UID_PRIFIX-testVMInstance
OS_IMAGE_NAME=$(echo $IMAGE_URL | rev |  cut -d '/' -f 1 | rev)
OS_ZONE="nova"

if [[ $(openstack image list -c Name -f value | grep "$OS_IMAGE_NAME" | wc -l) = 0 ]]; then
    wget $IMAGE_URL && openstack image create --file $OS_IMAGE_NAME --disk-format qcow2 --container-format bare --public $OS_IMAGE_NAME
fi

openstack flavor create --ram 256 --disk 1 --ephemeral 0 --vcpus 1 --public $OS_FLAVOR
openstack network create $OS_NETWORK && openstack subnet create --network $OS_NETWORK --subnet-range $SUBNET_RANGE $OS_SUBNET
openstack router create $OS_ROUTER --ha && openstack router set --external-gateway public $OS_ROUTER && openstack router add subnet $OS_ROUTER $OS_SUBNET
# HA router mode need to add check that all instances of router were scheduled and running
# neutron agent-list
# neutron router-list
# neutron l3-agent-list-hosting-router 8de4f574-63e3-42e4-bc2c-a13c0de49cfc

openstack security group create $OS_SECURITYGROUP
openstack security group rule create --ingress --protocol icmp $OS_SECURITYGROUP
openstack security group rule create --egress --protocol icmp $OS_SECURITYGROUP
openstack security group rule create --ingress --dst-port 22 --protocol tcp $OS_SECURITYGROUP

# declare -a createdInstancesList

for host in $(openstack host list -f value | grep compute | cut -d " " -f1 | tr '\n' ' '); do
    rand=$(tr -cd '[:digit:]' < /dev/urandom | fold -w8 | head -n1)
    openstack server create --image $OS_IMAGE_NAME --flavor $OS_FLAVOR --nic net-id=$OS_NETWORK --availability-zone $OS_ZONE:$host $OS_VMInstance-$rand
    createdInstancesList+=($OS_VMInstance-$rand)
done

# Need add checking of waiting for active status of instances
openstack server list
sleep 10

i=180
for instance in ${createdInstancesList[@]}; do
    openstack floating ip delete 10.11.12.$i || echo "No FloatingIP found for 10.11.12.$i"
    openstack server add security group $instance $OS_SECURITYGROUP
    openstack floating ip create  --floating-ip-address 10.11.12.$i --port $(openstack port list --server $instance -f value -c ID) public
    ((i++))
done

openstack server list

