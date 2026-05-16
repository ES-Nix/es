#!/usr/bin/env bash


DISK_NAME="${DISK_NAME:=mydisk.qcow2}"

_HOST_ARCH=$(uname -m)
case "$_HOST_ARCH" in
  x86_64)
    _QEMU_BIN="qemu-system-x86_64"
    _QEMU_MACHINE_ARGS=("-enable-kvm")
    _QEMU_DISK_ARGS=("-hda" "$DISK_NAME")
    _QEMU_CPU_ARGS=("-cpu" "Haswell-noTSX-IBRS,vmx=on")
    FULL_PATH_TO_OVMF="$(nix build --print-out-paths --no-link nixpkgs#OVMF.fd)/FV/OVMF.fd"
    ;;
  aarch64)
    _QEMU_BIN="qemu-system-aarch64"
    _QEMU_MACHINE_ARGS=("-enable-kvm" "-machine" "virt,gic-version=max" "-cpu" "host")
    _QEMU_DISK_ARGS=("-drive" "file=$DISK_NAME,if=virtio,format=qcow2")
    _QEMU_CPU_ARGS=()
    FULL_PATH_TO_OVMF="$(nix build --print-out-paths --no-link nixpkgs#OVMF.fd)/FV/AAVMF_CODE.fd"
    ;;
  *)
    _QEMU_BIN="qemu-system-${_HOST_ARCH}"
    _QEMU_MACHINE_ARGS=()
    _QEMU_DISK_ARGS=("-hda" "$DISK_NAME")
    _QEMU_CPU_ARGS=()
    FULL_PATH_TO_OVMF="${OVMF:-OVMF.fd}"
    ;;
esac

echo qemu-img info "$DISK_NAME"

qemu-img info "$DISK_NAME"


"$_QEMU_BIN" \
"${_QEMU_MACHINE_ARGS[@]}" \
"${_QEMU_CPU_ARGS[@]}" \
-m 6G \
-boot c \
"${_QEMU_DISK_ARGS[@]}" \
-bios "$FULL_PATH_TO_OVMF" \
-net nic,model=virtio \
-net user,hostfwd=tcp:127.0.0.1:10000-:10000 \
-device virtio-gpu-pci \
-device virtio-keyboard-pci \
-fsdev local,security_model=passthrough,id=fsdev0,path="$(pwd)" \
-device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostsharetag \
-nographic


#qemu-system-i386 \
#-m 256 \
#-kernel boot/vmlinuz-lts \
#-initrd boot/initramfs-lts \
#-append "console=ttyS0 ip=dhcp alpine_repo=http://dl-cdn.alpinelinux.org/alpine/edge/main/" \
#-virtfs local,path=/xxxx/mylocalfolder,mount_tag=mytag1,security_model=passthrough
#
#mount -t 9p -o trans=virtio hostsharetag /mnt
