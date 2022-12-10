#!/bin/sh
set -euxo pipefail

# wait until the system is ready to be managed.
$SHELL -c 'while ! esxcli system settings advanced list -o /UserVars/HostClientCEIPOptIn >/dev/null 2>&1; do sleep 5; done'

# do not Join the VMware Customer Experience Improvement Program.
esxcli system settings advanced set -o /UserVars/HostClientCEIPOptIn -i 2
