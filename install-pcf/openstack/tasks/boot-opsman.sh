#!/bin/bash

# If we are using a self signed SSL certificate,
# export the location so the openstack-cli uses it.

echo "$PRE_OS_CACERT" > /ca.crt
export OS_CACERT='/ca.crt'

function boot_opsman() {

  OPSMAN_FILE=$(find pivnet-opsman-product/ -name '*.raw')
  if [ -z $OPSMAN_FILE ]; then
    echo "FATAL: We didn't get an opsman image from Pivnet."
    exit 1
  fi

  VERSION=$(echo $OPSMAN_FILE | perl -lane "print \$1 if (/pcf-openstack-(.*?).raw/)")
  IMG_NAME="$OPS_MGR_IMG_NAME-$VERSION"

  echo "Looking for $IMG_NAME in glance."
  openstack image list | grep -q $IMG_NAME
  if [ $? != 0 ]; then 
    echo "$IMG_NAME is not available in glance."
    exit 1
  fi

  echo "Booting OpsMan: $OPS_MGR_SRV_NAME"
  openstack server create --image $IMG_NAME \
    --flavor $OPS_MGR_FLV_NAME --key-name $OPS_MGR_KEY_NAME \
    --security-group $OPS_MGR_SEC_GRP \
    --nic net-id=$INFRA_NETWORK $OPS_MGR_SRV_NAME

   if [ $? == 0 ]; then
     echo "Sleeping 20 seconds for the VM to boot before adding a floating IP."
     sleep 20 # Give openstack a few moments to get the VM organized.
     FLOAT=$( openstack floating ip create $EXTERNAL_NETWORK | \
              grep floating_ip_address | awk '{print $4}' )
     echo "Adding floating IP: $FLOAT to $OPS_MGR_SRV_NAME"
     openstack server add floating ip $OPS_MGR_SRV_NAME $FLOAT

     echo "Opsman URL: http://$FLOAT/"
   else
     echo "Failed to boot $OPS_MGR_SRV_NAME"
     openstack server show $OPS_MGR_SRV_NAME
   fi

}

boot_opsman
