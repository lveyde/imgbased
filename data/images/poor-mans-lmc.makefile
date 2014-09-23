
#
# How to use
# $ export ALL_PROXY=10.0.2.2:3128
# $ make run-install
#

KICKSTART = kickstarts/runtime-layout.ks

DISK_NAME = hda.qcow2
DISK_SIZE = 10G

VM_RAM = 2048
VM_SMP = 4

QEMU = qemu-kvm
QEMU_APPEND =
CURL = curl -L -O

FEDORA_RELEASE_URL = http://download.fedoraproject.org/pub/fedora/linux/releases/$(FEDORA_RELEASEVER)/Fedora/x86_64/os/
FEDORA_DEVELOPMENT_URL = http://download.fedoraproject.org/pub/fedora/linux/development/$(FEDORA_ANACONDA_RELEASEVER)/x86_64/os/

FEDORA_RELEASEVER = 21
FEDORA_ANACONDA_RELEASEVER = 21
FEDORA_URL = $(FEDORA_DEVELOPMENT_URL)
FEDORA_ANACONDA_URL = $(FEDORA_URL)


SHELL = /bin/bash


.INTERMEDIATE: spawned_pids

vmlinuz:
	$(CURL) $(FEDORA_ANACONDA_URL)/isolinux/vmlinuz

initrd.img:
	$(CURL) $(FEDORA_ANACONDA_URL)/isolinux/initrd.img

squashfs.img:
	$(CURL) $(FEDORA_ANACONDA_URL)/LiveOS/squashfs.img

define TREEINFO
[general]
name = Fedora-$(FEDORA_RELEASEVER)
family = Fedora
variant = Fedora
version = $(FEDORA_RELEASEVER)
packagedir =
arch = x86_64

[stage2]
mainimage = squashfs.img

[images-x86_64]
kernel = vmlinuz
initrd = initrd.img
endef

.PHONY: .treeinfo
export TREEINFO
.treeinfo:
	echo -e "$$TREEINFO" > $@

run-install: PYPORT:=$(shell echo $$(( 50000 + $$RANDOM % 15000 )) )
run-install: VNCPORT:=$(shell echo $$(( $$RANDOM % 1000 )) )
run-install: vmlinuz initrd.img squashfs.img .treeinfo $(KICKSTART)
	python -m SimpleHTTPServer $(PYPORT) & echo $$! > spawned_pids
	qemu-img create -f qcow2 $(DISK_NAME) $(DISK_SIZE)
	$(QEMU) \
		-vnc 0.0.0.0:$(VNCPORT) \
		-serial stdio \
		-smp $(VM_SMP) -m $(VM_RAM) \
		-hda $(DISK_NAME) \
		-kernel vmlinuz \
		-initrd initrd.img \
		-append "console=ttyS0 inst.repo=$(FEDORA_URL) inst.ks=http://10.0.2.2:$(PYPORT)/$(KICKSTART) inst.stage2=http://10.0.2.2:$(PYPORT)/ quiet $(QEMU_APPEND)" ; \
	kill $$(cat spawned_pids)
