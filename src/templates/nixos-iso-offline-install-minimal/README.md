



1) 
```bash
rm -fv mydisk.qcow2
nix run '.#' && nix run '.#run' 
```


2) For now no automatic login. So login with `nixuser` and password `1` 

3) In the VM's terminal:
```bash
# TODO: remove the nix-channel
sudo nix-channel --update -vv \
&& sudo nixos-rebuild list-generations --json \
&& sudo nixos-rebuild test \
&& sudo nixos-rebuild switch
```

```bash
# TODO: remove the nix-channel
sudo nix-channel --update -vv \
&& sudo -E nixos-rebuild list-generations --json \
&& sudo -E nixos-rebuild test \
&& sudo -E nixos-rebuild switch
```

sudo nixos-rebuild list-generations --json
nix eval nixpkgs#path

TODO: it should be an nix flake


### Details


TODO: 
- Explain how to pass env vars to scripts!
- Do it for other env vars!
```bash
export DISK_NAME=foo-bar-mydisk.qcow2
```



TODO: for some reason it was error outing even commented, why? 
```nix
    # registry.nixpkgs.flake = nixpkgs;
    # nixPath = [ "nixpkgs=${pkgs.path}" ]; # TODO: test it
```



TODO: 
- is it possible to make an systemd unity reboot the machine?
- the goal would be to change user id to match the host one.
```nix
  # https://unix.stackexchange.com/questions/619671/declaring-a-sym-link-in-a-users-home-directory#comment1159159_619703
  systemd.services.fix-mount = {
    script = ''
      echo "Fixing mount"
      #
      mkdir /home/nixuser/code
      chown nixuser:nixgroup /home/nixuser/code
      echo "echo 1 | sudo -S mount -t 9p -o trans=virtio hostsharetag /home/nixuser/code" >> /home/nixuser/.profile
    '';
    wantedBy = [ "multi-user.target" ];
  };
``` 







nix build --file '<nixpkgs/nixos>' system -I nixos-config=/mnt/etc/nixos/configuration.nix -o /out

nix build --offline --no-use-registries --file '<nixpkgs/nixos>' system -I nixos-config=/mnt/etc/nixos/configuration.nix -o /out
nix build --offline --no-use-registries --file "$HACK_NIX_PATH"'/nixos' system -I nixos-config=/mnt/etc/nixos/configuration.nix -o /out

nix eval --expr 'builtins.nixPath'
date --rfc-3339=ns --utc
date --iso-8601=ns --utc


environment.variables.HACK_NIX_PATH = "${pkgs.path}";

environment.etc."channels/nixpkgs".source = pkgs.path;


nixos-install \
--no-root-password \
--no-registries \
--no-channel-copy


ls -alh /mnt/root/.nix-defexpr/channels


sudo \
nix-build \
--out-link /mnt/system \
--store /mnt \
--extra-substituters "auto?trusted=1" \
"$HACK_NIX_PATH"'/nixos' \
-A system \
-I "nixos-config=/mnt/etc/nixos/configuration.nix"



```bash
nix-build \
--out-link /mnt/system \
--store /mnt \
--extra-substituters "auto?trusted=1" \
"${pkgs.path}"'/nixos' \
-A system \
-I "nixos-config=/mnt/etc/nixos/configuration.nix"


${installBuild.nixos-install}/bin/nixos-install \
--no-root-password \
--no-registries

ls -alh /mnt/system

time nix --option cores 8 build --print-build-logs --print-out-paths '.#ISONixOSSelfOfflineInstallISOInQcow2'
time nix --option cores 8 build --print-build-logs --print-out-paths --rebuild '.#ISONixOSSelfOfflineInstallISOInQcow2'
```


TODO: figure it out why so many bugs/race conditions using the script that install NixOS
```bash
Error: You requested a partition from 537MB to 11.8GB (sectors 1048576..23068671).
The closest location we can manage is 537MB to 537MB (sectors 1048575..1048575).
```

```bash
Error: primary partition table array CRC mismatch
```


```bash
Error: The backup GPT table is corrupt, but the primary appears OK, so that will be used.
Error: primary partition table array CRC mismatch
```



```bash
sudo fdisk -l

sudo parted /dev/sda align-check
```
Refs.:
- https://superuser.com/a/1378922



TODO: 
```bash
linux>   dependency already copied: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/hid/hid.ko.xz
linux>   dependency already copied: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/hid/usbhid/usbhid.ko.xz
linux>   copying dependency: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/hid/hid-corsair.ko.xz
linux> root module: pcips2
linux>   copying dependency: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/input/serio/serio.ko.xz
linux>   copying dependency: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/input/serio/pcips2.ko.xz
linux> root module: atkbd
linux>   copying dependency: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/input/vivaldi-fmap.ko.xz
linux>   dependency already copied: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/input/serio/serio.ko.xz
linux>   copying dependency: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/input/serio/libps2.ko.xz
linux>   copying dependency: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/input/keyboard/atkbd.ko.xz
linux> root module: i8042
linux>   dependency already copied: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/input/serio/serio.ko.xz
linux>   copying dependency: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/input/serio/i8042.ko.xz
linux> root module: rtc_cmos
linux>   copying dependency: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/rtc/rtc-cmos.ko.xz
linux> root module: dm_mod
linux>   copying dependency: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/dax/dax.ko.xz
linux>   copying dependency: /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/md/dm-mod.ko.xz
linux> firmware for /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/usb/host/xhci-pci.ko.xz: renesas_usb_fw.mem
linux> lib/firmware -> /nix/store/04mhgl5fdvlji9gishk49j52sazjqkx3-linux-6.6.56-modules-shrunk/lib/firmware
linux> WARNING: missing firmware renesas_usb_fw.mem for module /nix/store/r7c08gq8jbvwqnskpjbv4dp99fasq394-linux-6.6.56-modules/lib/modules/6.6.56/kernel/drivers/usb/host/xhci-pci.ko.xz
linux> depmod: WARNING: could not open modules.builtin.modinfo at /nix/store/04mhgl5fdvlji9gishk49j52sazjqkx3-linux-6.6.56-modules-shrunk/lib/modules/6.6.56: No such file or directory
error: derivation '/nix/store/gbab580sb7la6prasabjr6ipp51m2bcp-closure-info.drv' requires non-existent output 'bin' from input derivation '/nix/store/f3dhj2810j9apyrrdifp0n8h5madfia0-libidn2-2 /179m29,8s
```


TODO: 
```bash
<<< Welcome to NixOS 25.05.20250612.fd48718 (x86_64) - ttyS0 >>>
The "nixos" and "root" accounts have empty passwords.

To log in over ssh you must set a password for either "nixos" or "root"
with `passwd` (prefix with `sudo` for "root"), or add your public key to
/home/nixos/.ssh/authorized_keys or /root/.ssh/authorized_keys.

If you need a wireless connection, type
`sudo systemctl start wpa_supplicant` and configure a
network using `wpa_cli`. See the NixOS manual for details.


nixos login: nixos (automatic login)

The system was detected as UEFI
Model: ATA QEMU HARDDISK (scsi)
Disk /dev/sda: 15.0GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: 

Number  Start  End  Size  File system  Name  Flags

Model: ATA QEMU HARDDISK (scsi)
Disk /dev/sda: 15.0GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: 

Number  Start   End     Size    File system  Name  Flags
        17.4kB  15.0GB  15.0GB  Free Space

mke2fs 1.47.2 (1-Jan-2025)
Discarding device blocks: done                            
Creating filesystem with 2490368 4k blocks and 622592 inodes
Filesystem UUID: ba852055-bd2e-4d4f-adae-4446e42d57d6
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done 

Setting up swapspace version 1, size = 524 MiB (549449728 bytes)
LABEL=swap, UUID=5396cb65-30b7-4d46-97c3-ee3f3898bd3e
mkfs.fat 4.2 (2021-01-31)
mkdir: created directory '/mnt/boot'
mount: /mnt/boot: fsconfig() failed: /dev/disk/by-label/boot: Can't lookup blockdev.
       dmesg(1) may have more information after failed mount system call.

```


```bash
[   18.254468] NET: Registered PF_PACKET protocol family
[   21.427728] fbcon: Taking over console
[   21.507238] Console: switching to colour frame buffer device 160x50
[   24.182638]  sda:
[   24.456302]  sda:
[   24.915009]  sda: sda1
[   24.959977]  sda: sda1
[   27.770090] Adding 536572k swap on /dev/sda2.  Priority:-2 extents:1 across:536572k 
[   29.380768] EXT4-fs (sda1): mounted filesystem ba852055-bd2e-4d4f-adae-4446e42d57d6 r/w with ordered data mode. Quota mode: none.
```
