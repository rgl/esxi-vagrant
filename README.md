# Usage

**NB** These instructions are for an Ubuntu 20.04 host.

Download the [Free ESXi 6.7 (aka vSphere Hypervisor) iso file](https://www.vmware.com/go/get-free-esxi).

Install QEMU/KVM:

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

# Notes

* At the ESXi console you can press the following key
  combinations to switch between the virtual consoles:
  * `Alt+F1`: ESX Shell / Boot console.
  * `Alt+F2`: Direct Console User Interface (DCUI) console.
  * `Alt+F11`: Status console.
  * `Alt+F12`: Log console.
* In case you want to start virtual machines within the ESXi environment it is highly recommended
to enable nested virtualization on your host system, see:
  * [Fedora Docs: How to enable nested virtualization with KVM](https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/)

# Reference

* [VMware Docs: Installing or Upgrading Hosts by Using a Script](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.esxi.install.doc/GUID-870A07BC-F8B4-47AF-9476-D542BA53F1F5.html).
* [VMware Docs: Installation and Upgrade Script Commands](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.esxi.install.doc/GUID-61A14EBB-5CF3-43EE-87EF-DB8EC6D83698.html).
* [How to properly clone a Nested ESXi VM?](https://www.virtuallyghetto.com/2013/12/how-to-properly-clone-nested-esxi-vm.html).
* [vmk0 management network MAC address is not updated when NIC card is replaced or vmkernel has duplicate MAC address (1031111)](https://kb.vmware.com/s/article/1031111).
* [Applying vSphere host configuration changes after an unclean shutdown (2001780)](https://kb.vmware.com/s/article/2001780).
