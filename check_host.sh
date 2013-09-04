#!/bin/bash

. /etc/xensource-inventory
me=$INSTALLATION_UUID

errorsdetected=0

# Get names of domains running on this host.
domains=`list_domains -minimal`

# Check that each of the names given by list_domains corresponds to the UUID of
# a VM marked as resident on this host in xapi.
for domain in $domains
do
	echo "checking domain $domain"
	resident=`xe vm-list uuid=$domain params=resident-on --minimal`
	if [ "$me" != "$resident" ]
	then
		echo Possible problem detected: VM $domain has a domain but is isn\'t marked as resident in xapi
		errorsdetected=$((errorsdetected + 1))
	fi
done

# Get VDIs which have a tapdisk running on this host.
# "grep -v aio" excludes tapdisks corresponding to ISOs.
vdis=`tap-ctl list | grep -v aio | rev | cut -d/ -f1 | rev | grep -o '[0-9a-f][0-9a-f-]\+'`

# Check that for each of these tapdisks, there is at least one locally-resident
# VM with a VBD connecting it to this disk.
for vdi in $vdis
do
	echo "Checking VDI $vdi"
	vbds=`xe vbd-list vdi-uuid=$vdi currently-attached=true --minimal | tr , '\n'`

	resident_vm_exists=
	for vbd in $vbds
	do
		vm=`xe vbd-list uuid=$vbd params=vm-uuid --minimal`
		resident=`xe vm-list uuid=$vm params=resident-on --minimal`
		if [ "$me" = "$resident" ]
		then
			resident_vm_exists=true
		fi
	done
	if [ ! $resident_vm_exists ]
	then
		echo Possible problem detected: VDI $vdi is attached locally, but not to any resident VMs according to xapi
		errorsdetected=$((errorsdetected+1))
	fi
done

echo $errorsdetected errors detected

if [ $errorsdetected -gt 0 ]
then
	exit 1
fi



