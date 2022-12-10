# About

This is a packer template for installing ESXi inside a VM in a way that
can be later used as a vagrant base box.

**NB** This builds a base box **without any datastore**. This means you
have to create one yourself in your vagrant environment (see the
[vagrant example](example)).

**NB** If you want to create a base box with a datastore, you have to edit
the `esxi.json` file to add `autoPartitionOSDataSize=4096` to the
`boot_command` array (after the `ks=` element) and increase `disk_size` to
a size that is big enough to hold your datastore.

**NB** This is needed until [packer#9160](https://github.com/hashicorp/packer/issues/9160) and [vagrant-libvirt#602](https://github.com/vagrant-libvirt/vagrant-libvirt/issues/602) are addressed.

## Usage

**NB** These instructions are for an Ubuntu 22.04 host.

Install Packer 1.6.0+ ([because we need to use the qemu bridge mode](https://github.com/hashicorp/packer/issues/9156)).

Download the [Free ESXi 8.0 (aka vSphere Hypervisor) iso file](https://www.vmware.com/go/get-free-esxi).

### qemu-kvm usage

Install qemu-kvm:

```bash
apt-get install -y qemu-kvm
apt-get install -y sysfsutils
systool -m kvm_intel -v
```

Allow non-root users to add tap interfaces to a bridge:

```bash
# allow non-root users to add tap interfaces to virbr0.
# NB a tap (L2) interface is created by qemu when we use a bridge netdev.
sudo chmod u+s /usr/lib/qemu/qemu-bridge-helper
sudo bash -c 'mkdir -p /etc/qemu && echo "allow virbr0" >>/etc/qemu/bridge.conf'
```

Create the base box and follow the returned instructions:

```bash
time make build-libvirt
```

Launch the vagrant example:

```bash
apt-get install -y virt-manager libvirt-dev
vagrant plugin install vagrant-libvirt # see https://github.com/vagrant-libvirt/vagrant-libvirt
cd example
time vagrant up
```

Try using it:

```bash
vagrant ssh
ps -c
esxcli software vib list
esxcli system version get
exit
```

Create the [debian-vagrant base box and example](https://github.com/rgl/debian-vagrant) within this esxi instance.

#### raw qemu-kvm usage

To fiddle with ESXi it can be more straightforward to directly use qemu, e.g.:

```bash
# allow non-root users to add tap interfaces to virbr0.
# NB a tap (L2) interface is created by qemu when we use a bridge netdev.
sudo chmod u+s /usr/lib/qemu/qemu-bridge-helper
sudo bash -c 'mkdir -p /etc/qemu && echo "allow virbr0" >>/etc/qemu/bridge.conf'

# create an empty disk.
qemu-img create -f qcow2 test.qcow2 40G
qemu-img info test.qcow2

# launch the vm.
# NB to known the available options use:
#       qemu-system-x86_64 -machine help
#       qemu-system-x86_64 -cpu help
#       qemu-system-x86_64 -netdev help
#       qemu-system-x86_64 -device help
# see http://wiki.qemu.org/download/qemu-doc.html
qemu-system-x86_64 \
  -name 'ESXi Test Baseline' \
  -machine pc,accel=kvm \
  -cpu host \
  -m 4G \
  -smp cores=4 \
  -k pt \
  -qmp unix:test.socket,server,nowait \
  -netdev bridge,id=net0,br=virbr0 \
  -device vmxnet3,id=nic0,netdev=net0,mac=52:54:00:12:34:56 \
  -drive if=ide,media=disk,discard=unmap,format=qcow2,cache=unsafe,file=test.qcow2 \
  -drive if=ide,media=cdrom,file=VMware-VMvisor-Installer-8.0-20513097.x86_64.iso

# wait for the mac address to appear in the virbr0 interface, e.g. it
# should output something alike:
#   IP address       HW type     Flags       HW address            Mask     Device
#   192.168.121.111  0x1         0x2         52:54:00:12:34:56     *        virbr0
cat /proc/net/arp

# play with the qmp socket.
# see https://gist.github.com/rgl/dc38c6875a53469fdebb2e9c0a220c6c.
nc -U test.socket      # directly access the socket.
qmp-shell test.socket  # access it in a friendlier way.

# open a ssh session (after you enable ssh access in ESXi).
ssh -v root@192.168.121.111

# open a browser session.
xdg-open https://192.168.121.111
```

### VMware ESXi usage

Set your ESXi details, and test the connection to ESXi:

```bash
vagrant plugin install vagrant-vmware-esxi
cat >secrets.sh <<EOF
export ESXI_HOSTNAME='esxi.test'
export ESXI_USERNAME='root'
export ESXI_PASSWORD='HeyH0Password!'
export ESXI_DATASTORE='datastore1'
# NB for the nested VMs to access the network, this VLAN port group security
#    policy MUST be configured to Accept:
#      Promiscuous mode
#      Forged transmits
export ESXI_NETWORK='esxi'
export ESXI_TEMPLATE='template-esxi-8.0.0-amd64-esxi'
EOF
source secrets.sh
```

Upload the ESXi ISO to the datastore.

Type `make build-esxi` and follow the instructions.

Try the example vagrant example:

```bash
cd example
source ../secrets.sh
vagrant up --provider=vmware_esxi --no-destroy-on-error
vagrant ssh
ps -c
esxcli software vib list
esxcli system version get
exit
vagrant destroy -f
```

### VMware vSphere usage

Download [govc](https://github.com/vmware/govmomi/releases/latest) and place it inside your `/usr/local/bin` directory.

Set your vSphere details, and test the connection to vSphere:

```bash
sudo apt-get install build-essential patch ruby-dev zlib1g-dev liblzma-dev
vagrant plugin install vagrant-vsphere
cat >secrets.sh <<EOF
export GOVC_INSECURE='1'
export GOVC_HOST='vsphere.local'
export GOVC_URL="https://$GOVC_HOST/sdk"
export GOVC_USERNAME='administrator@vsphere.local'
export GOVC_PASSWORD='password'
export GOVC_DATACENTER='Datacenter'
export GOVC_CLUSTER='Cluster'
export GOVC_DATASTORE='Datastore'
export VSPHERE_OS_ISO="[$GOVC_DATASTORE] iso/VMware-VMvisor-Installer-8.0-20513097.x86_64.iso"
export VSPHERE_ESXI_HOST='esxi.local'
export VSPHERE_TEMPLATE_FOLDER='test/templates'
export VSPHERE_TEMPLATE_NAME="$VSPHERE_TEMPLATE_FOLDER/esxi-8.0.0-amd64-vsphere"
export VSPHERE_VM_FOLDER='test'
export VSPHERE_VM_NAME='esxi-vagrant-example'
# NB for the nested VMs to access the network, this VLAN port group security
#    policy MUST be configured to Accept:
#      Promiscuous mode
#      Forged transmits
export VSPHERE_VLAN='packer'
EOF
source secrets.sh
# see https://github.com/vmware/govmomi/blob/master/govc/USAGE.md
govc version
govc about
govc datacenter.info # list datacenters
govc find # find all managed objects
```

Upload the ESXi ISO to the datastore.

Type `make build-vsphere` and follow the instructions.

Try the example vagrant example:

```bash
cd example
source ../secrets.sh
vagrant up --provider=vsphere --no-destroy-on-error
vagrant ssh
ps -c
esxcli software vib list
esxcli system version get
exit
vagrant destroy -f
```

## Notes

* At the ESXi console you can press the following key
  combinations to switch between the virtual consoles:
  * `Alt+F1`: ESX Shell / Boot console.
  * `Alt+F2`: Direct Console User Interface (DCUI) console.
  * `Alt+F11`: Status console.
  * `Alt+F12`: Log console.
* In case you want to start virtual machines within the ESXi environment it is highly recommended
to enable nested virtualization on your host system, see:
  * [Fedora Docs: How to enable nested virtualization with KVM](https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/)

## Reference

* [VMware Docs: Installing or Upgrading Hosts by Using a Script](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-esxi-upgrade/GUID-870A07BC-F8B4-47AF-9476-D542BA53F1F5.html).
* [VMware Docs: Installation and Upgrade Script Commands](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.esxi.install.doc/GUID-61A14EBB-5CF3-43EE-87EF-DB8EC6D83698.html).
* [VMware Docs: Using vmkfstools](https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-storage/GUID-A5D85C33-A510-4A3E-8FC7-93E6BA0A048F.html).
* [How to properly clone a Nested ESXi VM?](https://williamlam.com/2013/12/how-to-properly-clone-nested-esxi-vm.html).
* [vmk0 management network MAC address is not updated when NIC card is replaced or vmkernel has duplicate MAC address (1031111)](https://kb.vmware.com/s/article/1031111).
* [Applying vSphere host configuration changes after an unclean shutdown (2001780)](https://kb.vmware.com/s/article/2001780).
* [Changing the default size of the ESX-OSData volume in ESXi 7.0](https://williamlam.com/2020/05/changing-the-default-size-of-the-esx-osdata-volume-in-esxi-7-0.html).
