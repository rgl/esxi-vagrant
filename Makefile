VERSION=$(shell jq -r .variables.version esxi.json)

help:
	@echo type make build-libvirt

build-libvirt: esxi-${VERSION}-amd64-libvirt.box

esxi-${VERSION}-amd64-libvirt.box: ks.cfg provision.sh esxi.json Vagrantfile.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=esxi-${VERSION}-amd64-libvirt -on-error=abort -timestamp-ui esxi.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f esxi-${VERSION}-amd64 esxi-${VERSION}-amd64-libvirt.box

tmp/esxi-7.iso:
	# see https://www.powershellgallery.com/packages/VMware.PowerCLI/12.0.0.15947286
	# see https://code.vmware.com/web/tool/12.0.0/vmware-powercli
	pwsh -Command 'if (!(Get-InstalledModule -ErrorAction SilentlyContinue VMware.PowerCLI)) { Install-Module VMware.PowerCLI -RequiredVersion 12.0.0.15947286 -Force }'
	mkdir -p tmp && wget -qOtmp/esxi-customizer.ps1 https://raw.githubusercontent.com/VFrontDe/ESXi-Customizer-PS/master/ESXi-Customizer-PS.ps1
	pwsh -Command 'cd tmp; .\esxi-customizer.ps1 -v70 -log "$$PWD/esxi-customizer.log"'
	# NB unfortunately this does not yet work in Ubuntu/Linux:
	# 		An unexpected error occurred:
	# 		The VMware.ImageBuilder module is not currently supported on the Core edition of PowerShell.
