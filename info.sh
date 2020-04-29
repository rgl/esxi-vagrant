#!/bin/sh
set -euxo pipefail
esxcli system version get
esxcli network nic list                 # vmnic (e.g. vmnic0)
esxcli network ip interface list        # vmknic (e.g. vmk0)
esxcli network vswitch standard list    # vSwitch (e.g. vSwitch0)
grep -E '[a-fA-F0-9]{2}(:[a-fA-F0-9]{2}){5}' /etc/vmware/esx.conf # show MAC addresses.
