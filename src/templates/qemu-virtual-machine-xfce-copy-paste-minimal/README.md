


```bash
nix \
run \
--refresh \
github:ES-nix/es#installQEMUVirtualMachineXfceCopyPasteMinimalTemplate \
&& cd QEMUVirtualMachineXfceCopyPasteMinimal
```


Cleaning:
```bash
cd .. && rm -frv QEMUVirtualMachineXfceCopyPasteMinimal
```

Subsequent iterations:
```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#vm
```


```bash
cat /var/log/X.0.log

grep QXL /var/log/X.0.log
grep virtio /var/log/X.0.lo
```
Refs.:
- https://www.linux-kvm.org/page/SPICE



```bash
ls -alh /dev/virtio-ports/com.redhat.spice.0
```


```bash
lspci | grep -F 'Red Hat, Inc.'
```

```bash
ps -lef | grep spice-vdagent
```
https://community.clearlinux.org/t/share-clipboard-and-file-transfer-between-host-and-kvm-qemu-guest/4689/4




```bash
#nix flake update \
#--override-input nixpkgs github:NixOS/nixpkgs/b0b2c5445c64191fd8d0b31f2b1a34e45a64547d \
#--override-input flake-utils github:numtide/flake-utils/5aed5285a952e0b949eb3ba02c12fa4fcfef535f
```

WIP:
```bash
nix flake update \
--override-input nixpkgs github:NixOS/nixpkgs/6eef602bdb2a316e7cf5f95aeb10b2ff0a97e4a5 \
--override-input flake-utils github:numtide/flake-utils/5aed5285a952e0b949eb3ba02c12fa4fcfef535f
```



```bash
systemctl is-active spice-vdagentd.service
```

```bash
journalctl -b -f -xeu spice-vdagentd.service
```

```bash
pgrep spice-vdagent | xargs -I{} echo /proc/{}/cmdline
```


```bash
cat /proc/$(pgrep -f qemu-kvm)/cmdline | xargs --null | sed 's@ -@ \\\n-@g'
```




```bash
ls -al ~/.local/share/xorg/Xorg.0.log
```



https://hydra.nixos.org/job/nixos/release-23.05/nixos.channel/all?page=9
https://hydra.nixos.org/build/222120866


```bash
nix eval --raw nixpkgs/ea4c80b39be4c09702b0cb3b42eab59e2ba4f24b#qemu.version
nix eval --raw nixpkgs/1732ee9120e43c1df33a33004315741d0173d0b2#qemu.version
nix eval --raw nixpkgs/9c8bff77b5d51380f5da349d0a6fc515da6244b0#qemu

nix eval --json nixpkgs/1732ee9120e43c1df33a33004315741d0173d0b2#qemu.configureFlags
nix eval --json nixpkgs/9c8bff77b5d51380f5da349d0a6fc515da6244b0#qemu.configureFlags
```


```bash
nix \
store \
ls \
--store https://cache.nixos.org/ \
--long \
--recursive \
"$(nix eval --raw nixpkgs/9c8bff77b5d51380f5da349d0a6fc515da6244b0#qemu)"/bin
```

```bash
echo foo-guest-bar | DISPLAY=:0 xsel -ib
```

```bash
echo foo-host-bar | DISPLAY=:0 xsel -ib
```


nixosConfigurations.vm.config.virtualisation.vmVariant.virtualisation.qemu.options

```bash
udevadm info -e ???
```


```bash
udevadm info /dev/virtio-ports/com.redhat.spice.0
```


```bash
P: /devices/pci0000:00/0000:00:0a.0/virtio7/virtio-ports/vport7p1
M: vport7p1
R: 1
U: virtio-ports
D: c 249:1
N: vport7p1
L: 0
S: virtio-ports/com.redhat.spice.0
E: DEVPATH=/devices/pci0000:00/0000:00:0a.0/virtio7/virtio-ports/vport7p1
E: DEVNAME=/dev/vport7p1
E: MAJOR=249
E: MINOR=1
E: SUBSYSTEM=virtio-ports
E: USEC_INITIALIZED=2563668
E: PATH=/nix/store/h44q3jiancpswzr21cqrb4d32r18k4ka-udev-path/bin:/nix/store/h44q3jiancpswzr21cqrb4d32r18k4ka-udev-path/sbin
E: DEVLINKS=/dev/virtio-ports/com.redhat.spice.0
E: TAGS=:systemd:
E: CURRENT_TAGS=:systemd:
```



```bash
find /sys/class/input/ -name mouse* -exec udevadm info -a {} \; | grep 'ATTRS{name}'
```
Refs.:
- https://wiki.archlinux.org/title/Touchpad_Synaptics#System_with_multiple_X_sessions


```bash
lsblk --nodeps --output NAME,MODEL,SERIAL
```


```bash
ls -l /dev/disk/by-id/ \
| grep sd \
| grep -v "part\|wwn" \
| awk '{print $9}' \
| uniq 
```
Refs.:
- https://groups.google.com/g/comp.os.linux.misc/c/s5JxbXx83ro/m/kBmaThyqDAAJ 


```bash
grep -h 'ID_SERIAL' /run/udev/data/b* | sort -uV
```


```bash
lsblk --output NAME,KNAME,RA,RM,RO,SIZE,TYPE,FSTYPE,LABEL,PARTLABEL,MOUNTPOINT,UUID,PARTUUID,WWN,MODEL,ALIGNMENT
```

```bash
blkid -s device -s LABEL -s TYPE -s LABEL -s UUID | sort -V
```
Refs.:
- https://groups.google.com/g/comp.os.linux.misc/c/s5JxbXx83ro/m/X4gl9_WRAQAJ



```bash
udevadm monitor --environment --udev
```


```bash
udevadm info --query=all --name=/dev/input/mice
```
Refs.:
- https://unix.stackexchange.com/a/650433 only place that documents it!
- https://unix.stackexchange.com/a/638265 read it!
- https://unix.stackexchange.com/a/502850 read it!

```bash
udevadm info --query=all --name=/dev/input/mouse0
```


```bash
notify-send "Bip Bop Bup" \
"$(lsblk --nodeps --output NAME,MODEL,SERIAL /dev/sd?)"
```

```bash
udevadm control --log-priority=debug
journalctl -f
```
https://unix.stackexchange.com/a/470963


```bash
udevadm hwdb --update
udevadm trigger /dev/input/eventX
udevadm info /dev/input/eventX
```
Refs:
- https://ubuntu-mate.community/t/mouse-settings-are-misleading/26328/3



```bash
sudo dd if=/dev/input/mice bs=1 count=100 | hexdump -C
```
Refs.:
- https://askubuntu.com/q/913192

```bash
sudo dd if=/dev/vport7p1 bs=1 count=100 | hexdump -C
```


```bash
lsof +D /dev/vport7p1
```


```bash
qemu-system-x86_64 -enable-kvm -m 8192 -boot d -cdrom nixos-gnome-23.11.2596.c1be43e8e837-x86_64-linux.iso -device virtio-rng-pci \
-net nic,netdev=user.0,model=virtio \
-netdev user,id=user.0, \
-vga virtio \
-display gtk \
-device qemu-xhci,id=xhci \
-chardev qemu-vdagent,id=ch1,name=vdagent,clipboard=on \
-device virtio-serial-pci \
-device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0 \
-device virtio-keyboard \
-usb \
-device usb-tablet,bus=usb-bus.0 -hda nixos.img
```


qemu-kvm \
-machine vmport=off \
-boot order=dc \
-vga qxl \
-spice port=3001,disable-ticketing \
-soundhw hda \
-device virtio-serial \
-chardev spicevmc,id=vdagent,debug=0,name=vdagent \
-device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
-cdrom /path/to/your.iso /path/to/your.img