# About

**WARNING: THIS IS NOT YET WORKING.**

For some reason vmxnet3 and the qemu user mode networking do not seem to
work together. As such, packer is not able to connect to the SSH daemon
and will not be able to complete the installation. Thou, this will work
[when packer supports the qemu bridge mode](https://github.com/hashicorp/packer/issues/9156).

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

**NB** These instructions are for an Ubuntu 20.04 host.

Download the [Free ESXi 7.0 (aka vSphere Hypervisor) iso file](https://www.vmware.com/go/get-free-esxi).

### qemu-kvm

Install qemu-kvm:

```bash
apt-get install -y qemu-kvm
apt-get install -y sysfsutils
systool -m kvm_intel -v
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

#### raw qemu-kvm

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
  -drive if=ide,media=cdrom,file=VMware-VMvisor-Installer-7.0.0-15843807.x86_64.iso

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

* [VMware Docs: Installing or Upgrading Hosts by Using a Script](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.esxi.install.doc/GUID-870A07BC-F8B4-47AF-9476-D542BA53F1F5.html).
* [VMware Docs: Installation and Upgrade Script Commands](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.esxi.install.doc/GUID-61A14EBB-5CF3-43EE-87EF-DB8EC6D83698.html).
* [VMware Docs: Using vmkfstools](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.storage.doc/GUID-A5D85C33-A510-4A3E-8FC7-93E6BA0A048F.html).
* [How to properly clone a Nested ESXi VM?](https://www.virtuallyghetto.com/2013/12/how-to-properly-clone-nested-esxi-vm.html).
* [vmk0 management network MAC address is not updated when NIC card is replaced or vmkernel has duplicate MAC address (1031111)](https://kb.vmware.com/s/article/1031111).
* [Applying vSphere host configuration changes after an unclean shutdown (2001780)](https://kb.vmware.com/s/article/2001780).
* [Changing the default size of the ESX-OSData volume in ESXi 7.0](https://www.virtuallyghetto.com/2020/05/changing-the-default-size-of-the-esx-osdata-volume-in-esxi-7-0.html).
