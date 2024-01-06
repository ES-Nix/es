


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
ps -lef | grep spice-vdagentd
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
--override-input nixpkgs github:NixOS/nixpkgs/2c9c58e98243930f8cb70387934daa4bc8b00373 \
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
