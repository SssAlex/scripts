#!/bin/bash

set -x

source osclient/bin/activate

export OS_CACERT=/etc/ssl/certs/
export OS_CLOUD=openstack_helm

### Remove resources
for instance in $(openstack server list -f value | grep testVMInstance | cut -d " " -f2 | tr '\n' ' '); do
    openstack server delete $instance
done
for securityGroup in $(openstack security group list -f value -c Name | grep testSecurityGroup | tr '\n' ' '); do
    openstack security group delete $securityGroup
done
for floatingIPAddress in $(openstack floating ip list -f value -c "Floating IP Address" | grep "10.11.12." | tr '\n' ' '); do
    openstack floating ip delete $floatingIPAddress
done
for port in $(openstack port list -f value | grep 172.30.100 | cut -d " " -f1 | tr '\n' ' ' ); do
    openstack port set $port --device-owner none
    openstack port delete $port
done
for network in $(openstack network list -f value -c Name | grep "testNetwork" | tr '\n' ' '); do
    openstack network delete $network
done
for router in $(openstack router list -f value -c Name | grep "testRouter" | tr '\n' ' '); do
    openstack router delete $router
done
for flavor in $(openstack flavor list -f value -c Name | grep "testFlavor" | tr '\n' ' '); do
    openstack flavor delete $flavor
done
