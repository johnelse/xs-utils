#!/bin/bash

. /etc/xensource-inventory
me=$INSTALLATION_UUID

errorsdetected=0

# Get names of domains running on this host.
domains=`list_domains -minimal`

# Check that each of the names given by list_domains corresponds to the UUID of
# a VM marked as resident on this host in xapi.
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

# Get VDIs which have a tapdisk running on this host.
vdis=`tap-ctl list | rev | cut -d/ -f1 | rev | grep -o '[0-9a-f][0-9a-f-]\+'`

# Check each of these corresponds to an attached VBD owned by
# a locally-resident VM.
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



