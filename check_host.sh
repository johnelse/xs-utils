#!/bin/bash

. /etc/xensource-inventory
domains=`list_domains -minimal`
me=$INSTALLATION_UUID

errorsdetected=0

for i in $domains
do
	echo "checking domain $i"
	resident=`xe vm-list uuid=$i params=resident-on --minimal`
	if [ 'x$me' != 'x$resident' ]
	then
		echo Possible problem detected: check VM $i
		errorsdetected=$((errorsdetected + 1))
	fi
done

vdis=`tap-ctl list | rev | cut -d/ -f1 | rev | grep -o '[0-9a-f][0-9a-f-]\+'`

for i in $vdis
do
	echo "Checking VDI $i"
	vbds=`xe vbd-list vdi-uuid=$i currently-attached=true --minimal`
	if [ 'x$vbds' = 'x' ]
	then
		echo Possible problem with VDI $i: No VBD found
		errorsdetected=$((errorsdetected+1))	
	fi

	for vbd in $vbds
	do
		vm=`xe vbd-list uuid=$vbd params=vm-uuid --minimal`
		resident=`xe vm-list uuid=$vm params=resident-on --minimal`
		if [ x$me != x$resident ]
		then
			echo Possible problem detected: VDI $i is attached locally but its VM $vm isn\'t resident
			errorsdetected=$((errorsdetected+1))
		fi	
	done
done

echo $errorsdetected errors detected

if [ $errorsdetected > 0 ]
then
	exit 1
fi



