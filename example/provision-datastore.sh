#!/bin/sh
set -euxo pipefail

datastore_name='datastore1'
# e.g. ide.0:1,t10.ATA_____QEMU_HARDDISK___________________________QM00002_____________,
disk_device="/vmfs/devices/disks/$(
    esxcli --formatter=csv --format-param=fields=TargetIdentifier,Device storage core path list \
        | awk -F, '/^(ide|pscsi)\.0:1,/{print $2}')"

# initialize the disk with a GPT partition/label.
partedUtil mklabel $disk_device gpt

# partition the disk with a single partion that spans the entire disk.
# NB syntax is setptbl <disk_device> <label> "<partition_number> <start_sector> <end_sector> <type> <attributes>"
# NB 2048 is the recommended starting sector for vmfs to align it with the vmfs block size.
# NB AA31E02A400F11DB9590000C2911D1B8 is GPT GUID/type for vmfs as returned by partedUtil showGuids.
end_sector="$(partedUtil getUsableSectors $disk_device | awk '{print $2}')"
partedUtil setptbl $disk_device gpt "1 2048 $end_sector AA31E02A400F11DB9590000C2911D1B8 0"

# create the datastore vmfs in the first partition of the disk.
# see https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.storage.doc/GUID-A5D85C33-A510-4A3E-8FC7-93E6BA0A048F.html
vmkfstools --createfs vmfs6 --setfsname $datastore_name --blocksize 1m "$disk_device:1"

# show summary.
partedUtil getptbl $disk_device
partedUtil partinfo $disk_device 1
vmkfstools --queryfs /vmfs/volumes/$datastore_name
vmkfstools --activehosts /vmfs/volumes/$datastore_name
