#!/bin/sh

if [ $# -ne 3 ]
then
    echo "usage: $0 <branch> <sr-uuid> <name-label>"
    exit 1
fi

BRANCH=$1
SR_UUID=$2
NAME_LABEL=$3
MOUNT_POINT=/mnt

set -x

# Import the VM.
wget http://coltrane.eng.hq.xensource.com/usr/groups/build/${BRANCH}/xe-phase-2-latest/xe-phase-2/ddk.iso -O ddk.iso
mountpoint -q $MOUNT_POINT && umount $MOUNT_POINT
mount -o loop ddk.iso $MOUNT_POINT
VM=`xe vm-import filename=${MOUNT_POINT}/ddk/ova.xml sr-uuid=${SR_UUID}`

# Setup the VM.
xe vm-memory-limits-set uuid=${VM} dynamic-min=2147483648 dynamic-max=2147483648 static-min=2147483648 static-max=2147483648
xe vm-param-set uuid=${VM} VCPUs-max=4 VCPUs-at-startup=4 name-label=${NAME_LABEL}
VDI=`xe vdi-create type=user sr-uuid=${SR_UUID} name-label="DDK data VDI" virtual-size=21474836480`
xe vbd-create vm-uuid=${VM} vdi-uuid=${VDI} device=autodetect type=Disk mode=RW
