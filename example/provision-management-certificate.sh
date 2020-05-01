#!/bin/sh
set -eux

fqdn="$(hostname -f)"

# provision the certificate.
cp /tmp/tls/$fqdn-crt.pem /etc/vmware/ssl/rui.crt
chmod 644 /etc/vmware/ssl/rui.crt
chown root:root /etc/vmware/ssl/rui.crt
cp /tmp/tls/$fqdn-key.pem /etc/vmware/ssl/rui.key
chmod 400 /etc/vmware/ssl/rui.key
chown root:root /etc/vmware/ssl/rui.key

# restart the management services.
# NB for troubleshooting see /var/run/log/hostd.log and /var/run/log/vpxa.log
/etc/init.d/hostd restart
/etc/init.d/vpxa restart

# wait a bit for the services to settle down.
sleep 10

# delete the temporary files.
rm -rf /tmp/tls
