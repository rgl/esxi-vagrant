#!/bin/bash
set -euxo pipefail

vm_uuid="$1"
disk_size_gb="$2"

vm_disks="$(govc vm.info --vm.uuid "$vm_uuid" -json | jq -r '.VirtualMachines[].Layout.Disk[].DiskFile[]')"
if [ "$(echo "$vm_disks" | wc -l)" == '1' ]; then
    echo 'Adding the datastore disk...'
    # NB vm_disks will contain a single string with something like:
    #       [datastore] esxi-vagrant-example/esxi-vagrant-example.vmdk
    vm_data_disk_datastore="$(echo "$vm_disks" | awk '{print $1}' | tr -d '[]')"
    vm_data_disk_name="$(echo "$vm_disks" | awk '{print $2}' | sed 's,\.vmdk,-datastore.vmdk,')"
    govc vm.disk.create \
        --vm.uuid "$vm_uuid" \
        "-ds=$vm_data_disk_datastore" \
        "-name=$vm_data_disk_name" \
        -size "${disk_size_gb}GB"
fi
