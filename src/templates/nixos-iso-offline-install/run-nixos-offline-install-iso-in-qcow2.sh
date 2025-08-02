#!/usr/bin/env bash





#nix build .#nixos-offline-install-iso-in-qcow2 \
#|| nix build 'git+ssh://git@github.com/imobanco/income-fullstack?ref=feature/inicial-stuff#nixos-offline-install-iso-in-qcow2'


VM_DISK_NAME="${DISK_NAME:-mydisk.qcow2}"
VM_ISO_FULL_PATH="${ISO_FULL_PATH:-result/iso/*.iso}"
VM_DISK_SIZE="${DISK_SIZE:-12G}"
VM_RAM_SIZE="${RAM_SIZE:-2G}"
VM_OVMF_FULL_PATH_TO_OVMF="${OVMF_FULL_PATH_TO_OVMF:-OVMF.fd}"

# rm -fv "$DISK_NAME"
qemu-img create -f qcow2 "$VM_DISK_NAME" 14G

echo qemu-img info "$DISK_NAME"

qemu-img info "$VM_DISK_NAME"

# echo $VM_ISO_FULL_PATH
# FULL_PATH_TO_OVMF=$(nix build --print-out-paths --no-link nixpkgs#OVMF.fd)/FV/OVMF.fd


qemu-system-x86_64 \
-enable-kvm \
-boot d \
-hda "$VM_DISK_NAME" \
-m 4G \
-bios "$VM_OVMF_FULL_PATH_TO_OVMF" \
-cdrom "$VM_ISO_FULL_PATH" \
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
