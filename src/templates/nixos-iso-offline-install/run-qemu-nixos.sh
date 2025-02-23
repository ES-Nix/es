#!/usr/bin/env bash


DISK_NAME="${DISK_NAME:=mydisk.qcow2}"
FULL_PATH_TO_OVMF="$(nix build --print-out-paths --no-link nixpkgs#OVMF.fd)/FV/OVMF.fd"


#rm -fv "$DISK_NAME"
#qemu-img create -f qcow2 "$DISK_NAME" 12G

echo qemu-img info "$DISK_NAME"

qemu-img info "$DISK_NAME"


qemu-kvm \
-enable-kvm \
-m 6G \
-boot a \
-hda "$DISK_NAME" \
-bios "$FULL_PATH_TO_OVMF" \
-net nic,model=virtio \
-net user,hostfwd=tcp:127.0.0.1:10000-:10000 \
-device virtio-gpu-pci \
-device virtio-keyboard-pci \
-fsdev local,security_model=passthrough,id=fsdev0,path="$(pwd)" \
-device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostsharetag \
-cpu Haswell-noTSX-IBRS,vmx=on \
-nographic


#qemu-system-i386 \
#-m 256 \
#-kernel boot/vmlinuz-lts \
#-initrd boot/initramfs-lts \
#-append "console=ttyS0 ip=dhcp alpine_repo=http://dl-cdn.alpinelinux.org/alpine/edge/main/" \
#-virtfs local,path=/xxxx/mylocalfolder,mount_tag=mytag1,security_model=passthrough
#
#mount -t 9p -o trans=virtio hostsharetag /mnt
