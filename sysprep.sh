#!/bin/sh
set -euxo pipefail

# install the packer VIB (vSphere Installation Bundle) to automatically
# configure the system to handle packer deployments with the
# vmware-iso packer builder:
#   * enable guest ARP inspection to get their IP addresses (aka the Guest IP Hack).
#   * configure the firewall to allow vnc connections (5900-6000 ports).
#     NB ESXi 6.7+ exposes VNC through a websocket (at the same 443 port as the
#        api), so this firewall part is no longer needed and should be removed.
# see https://github.com/umich-vci/packer-vib
esxcli software acceptance set --level=CommunitySupported
esxcli software vib install -v https://github.com/umich-vci/packer-vib/releases/download/v1.0.0-1/packer.vib

# create a temporary copy before directly change it.
cp /etc/vmware/esx.conf /tmp/esx.conf.orig

# delete the system uuid.
# see https://www.virtuallyghetto.com/2013/12/how-to-properly-clone-nested-esxi-vm.html
sed -i -E '/^\/system\/uuid = /d' /etc/vmware/esx.conf

# show our changes.
diff -u /tmp/esx.conf.orig /etc/vmware/esx.conf || true

# get rid of harcoded mac address settings.
esxcli system settings advanced set -o /Net/FollowHardwareMac -i 1

# make changes permanent.
/sbin/auto-backup.sh
