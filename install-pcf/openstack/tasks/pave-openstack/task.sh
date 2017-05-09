#!/bin/bash

echo "$PRE_OS_CACERT" > /ca.crt
export OS_CACERT='/ca.crt'

function check_rc() {

  # Check the return code of previous command.
  local RC=$1
  if [ $RC != 0 ]; then
    echo "Failed"
    exit 1
  else
    echo "Ok"
  fi
}

function create_private_network() {

  local NETNAME=$1
  local SUBNET=$2

  echo -n "Creating Network $NETNAME ($SUBNET): "
  openstack network create $NETNAME 
  openstack subnet create ${NETNAME}-subnet --network $NETNAME --subnet-range $SUBNET 
  check_rc $?
}

function create_admin_router() {

  local ROUTER=$1
  echo -n "Creating router $ROUTER: "

  openstack router create $ROUTER
  neutron router-gateway-set $ROUTER $EXTERNAL_NETWORK
  openstack router add subnet $ROUTER ${INFRA_NETWORK}-subnet
  openstack router add subnet $ROUTER ${ERT_NETWORK}-subnet
  openstack router add subnet $ROUTER ${SERVICES_NETWORK}-subnet
  openstack router add subnet $ROUTER ${SERVICESOD_NETWORK}-subnet
  check_rc $?
}

function create_backend_router() {

  local ROUTER=$1
  echo -n "Creating router $ROUTER: "
  openstack router create $ROUTER
  openstack router add subnet $ROUTER ${INFRA_NETWORK}-subnet
}

function create_secgroup() {

   local SECGROUP_NAME=$1

   openstack security group list | grep -w " $SECGROUP_NAME "
   if [ $? != 0 ]; then
     echo -n "Creating CF security group: "

     openstack security group create $SECGROUP_NAME
     check_rc $?
   
     echo -"Adding rules to security group CF"
     # TCP
     for port in 22 80 443 4443; do 
       echo -n " - adding tcp $port: "
         neutron security-group-rule-create --direction ingress \
           --ethertype IPv4 --protocol tcp --port-range-min $port \
           --port-range-max $port $SECGROUP_NAME
       check_rc $?
     done
     echo -n " - adding icmp: "
     neutron security-group-rule-create --protocol icmp \
       --direction ingress --remote-ip-prefix 0.0.0.0/0 $SECGROUP_NAME
     check_rc $?
     for port in 68 3457; do
       echo -n " - adding udp $port: "
         neutron security-group-rule-create --direction ingress \
           --ethertype IPv4 --protocol udp --port-range-min $port \
           --port-range-max $port $SECGROUP_NAME
       check_rc $?
     done

   else
     echo "Ok"
   fi
}

create_private_network $INFRA_NETWORK $INFRA_SUBNET
create_private_network $ERT_NETWORK $ERT_SUBNET
create_private_network $SERVICES_NETWORK $SERVICES_SUBNET
create_private_network $SERVICESOD_NETWORK $SERVICESOD_SUBNET
create_admin_router $ADMIN_ROUTER
#create_backend_router $BACKEND_ROUTER
create_secgroup $SECGROUP_NAME

pivnet-cli --version
om-tool --version

