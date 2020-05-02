# About

This is a packer template for installing ESXi inside a VM in a way that
can be later used as a vagrant base box.

## Usage

**NB** These instructions are for an Ubuntu 20.04 host.

Download the [Free ESXi 6.7 (aka vSphere Hypervisor) iso file](https://www.vmware.com/go/get-free-esxi).

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

To fiddle with ESXi it can be more straightforward to directly use qemu.

Start with a known working configuration:

```bash
# create an empty disk.
qemu-img create -f qcow2 test-baseline.qcow2 40G
qemu-img info test-baseline.qcow2

# launch the vm.
# NB to known the available options use:
#       qemu-system-x86_64 -machine help
#       qemu-system-x86_64 -cpu help
#       qemu-system-x86_64 -netdev help
#       qemu-system-x86_64 -device help
# NB in a netdev user network, the following IP addresses exist:
#       10.0.2.2  gateway (host)
#       10.0.2.3  dns/dhcp
#       10.0.2.15 guest
# see http://wiki.qemu.org/download/qemu-doc.html
qemu-system-x86_64 \
  -name 'ESXi Test Baseline' \
  -machine pc,accel=kvm \
  -cpu host \
  -m 4G \
  -smp cores=4 \
  -k pt \
  -netdev user,id=net0,hostfwd=tcp::20022-:22,hostfwd=tcp::20443-:443 \
  -device e1000,netdev=net0,mac=52:54:00:12:34:56 \
  -drive if=ide,media=disk,discard=unmap,format=qcow2,cache=unsafe,file=test-baseline.qcow2 \
  -drive if=ide,media=cdrom,file=VMware-VMvisor-Installer-6.7.0.update03-14320388.x86_64.iso

# list the open sockets by qemu.
ss -4antp | grep qemu

# open a ssh session (after you enable ssh access in ESXi).
ssh -v root@127.0.0.1 -p 20022

# open a browser session.
xdg-open https://127.0.0.1:20443
```

Then fiddle with it, e.g., use a `vmxnet3` network device bridged to `virbr0`:

```bash
# create an empty disk.
qemu-img create -f qcow2 test-fiddle.qcow2 40G
qemu-img info test-fiddle.qcow2

# allow non-root users to add tap interfaces to virbr0.
# NB a tap (L2) interface is created by qemu when we use a bridge netdev.
sudo chmod u+s /usr/lib/qemu/qemu-bridge-helper
sudo bash -c 'mkdir -p /etc/qemu && echo "allow virbr0" >>/etc/qemu/bridge.conf'

# launch the vm.
qemu-system-x86_64 \
  -name 'ESXi Test Fiddle' \
  -machine pc,accel=kvm \
  -cpu host \
  -m 4G \
  -smp cores=4 \
  -k pt \
  -netdev bridge,id=net0,br=virbr0 \
  -device vmxnet3,netdev=net0,mac=52:54:00:12:34:56 \
  -drive if=ide,media=disk,discard=unmap,format=qcow2,cache=unsafe,file=test-fiddle.qcow2 \
  -drive if=ide,media=cdrom,file=VMware-VMvisor-Installer-6.7.0.update03-14320388.x86_64.iso

# wait for the mac address to appear in the virbr0 interface, e.g. it
# should output something alike:
#   IP address       HW type     Flags       HW address            Mask     Device
#   192.168.121.111  0x1         0x2         52:54:00:12:34:56     *        virbr0
cat /proc/net/arp

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

* [VMware Docs: Installing or Upgrading Hosts by Using a Script](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.esxi.install.doc/GUID-870A07BC-F8B4-47AF-9476-D542BA53F1F5.html).
* [VMware Docs: Installation and Upgrade Script Commands](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.esxi.install.doc/GUID-61A14EBB-5CF3-43EE-87EF-DB8EC6D83698.html).
* [How to properly clone a Nested ESXi VM?](https://www.virtuallyghetto.com/2013/12/how-to-properly-clone-nested-esxi-vm.html).
* [vmk0 management network MAC address is not updated when NIC card is replaced or vmkernel has duplicate MAC address (1031111)](https://kb.vmware.com/s/article/1031111).
* [Applying vSphere host configuration changes after an unclean shutdown (2001780)](https://kb.vmware.com/s/article/2001780).
