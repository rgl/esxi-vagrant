# Usage

Download the [Free ESXi 6.7 (aka vSphere Hypervisor) iso file](https://www.vmware.com/go/get-free-esxi).

Create the base box and follow the returned instructions:

```bash
time make build-libvirt
```

**NB** the [MAC address has to be hard-coded](https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1099).
if you known another solution, please let me know!

Launch the vagrant example:

```bash
cd example
time vagrant up
```

# Notes

* At the ESXi console you can press the following key
  combinations to switch between the virtual consoles:
  * `Alt+F1`: ESX Shell / Boot console.
  * `Alt+F2`: Direct Console User Interface (DCUI) console.
  * `Alt+F11`: Status console.
  * `Alt+F12`: Log console.

# Reference

* [VMware Docs: Installing or Upgrading Hosts by Using a Script](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.esxi.install.doc/GUID-870A07BC-F8B4-47AF-9476-D542BA53F1F5.html).
* [VMware Docs: Installation and Upgrade Script Commands](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.esxi.install.doc/GUID-61A14EBB-5CF3-43EE-87EF-DB8EC6D83698.html).
