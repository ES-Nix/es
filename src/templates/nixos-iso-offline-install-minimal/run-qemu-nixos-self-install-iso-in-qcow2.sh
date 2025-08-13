#!/usr/bin/env bash





nix build .#nixos-offline-install-iso-in-qcow2 \
|| nix build 'git+ssh://git@github.com/imobanco/income-fullstack?ref=feature/inicial-stuff#nixos-offline-install-iso-in-qcow2'


DISK_NAME=mydisk.qcow2

# rm -fv "$DISK_NAME"
qemu-img create -f qcow2 "$DISK_NAME" 12G

echo qemu-img info "$DISK_NAME"

qemu-img info "$DISK_NAME"


FULL_PATH_TO_OVMF=$(nix build --print-out-paths --no-link nixpkgs#OVMF.fd)/FV/OVMF.fd


qemu-system-x86_64 \
-enable-kvm \
-boot d \
-hda "$DISK_NAME" \
-m 3G \
-bios "$FULL_PATH_TO_OVMF" \
-cdrom result/iso/*.iso \
--net nic,model=virtio \
--net user,hostfwd=tcp:127.0.0.1:10000-:10000 \
--device virtio-gpu-pci \
--device virtio-keyboard-pci \
-fsdev local,security_model=passthrough,id=fsdev0,path="$(pwd)" \
-device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostsharetag \
-nographic

#-net none \

#qemu-kvm \
#-enable-kvm \
#-m 4G \
#-boot a \
#-hda "$DISK_NAME" \
#-bios "$FULL_PATH_TO_OVMF"
