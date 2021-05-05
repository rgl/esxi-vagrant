#!/bin/sh
set -euxo pipefail
esxcli system version get
esxcli network nic list                 # vmnic (e.g. vmnic0)
esxcli network ip interface list        # vmknic (e.g. vmk0)
esxcli network ip interface ipv4 get    # vmknic IP addresses.
esxcli network vswitch standard list    # vSwitch (e.g. vSwitch0)
