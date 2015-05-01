#!/bin/sh

if [ $# -ne 1 ]
then
    echo "Need 1 argument, got $#"
    exit 1
fi

vm_name=$1
vdi_name=${vm_name}_disk

sr_uuid=`xe sr-list name-label="Local storage" --minimal`

vm_uuid=`xe vm-create name-label=$vm_name`
vdi_uuid=`xe vdi-create sr-uuid=$sr_uuid type=user virtual-size=1000000 name-label=$vdi_name`
xe vbd-create vm-uuid=$vm_uuid vdi-uuid=$vdi_uuid mode=RW bootable=true type=Disk device=autodetect > /dev/null
echo $vm_uuid
