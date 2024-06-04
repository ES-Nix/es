


```bash
nix \
run \
--refresh \
github:ES-nix/es#installQEMUVirtualMachineXfceCopyPasteTemplate \
&& cd QEMUVirtualMachineXfceCopyPaste
```


```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#vm
```



References:
- https://github.com/NixOS/nixpkgs/issues/84105#issuecomment-674727693
- https://dataswamp.org/~solene/2021-05-08-openbsd-vmm-nixos.html
- https://github.com/nix-community/srvos/blob/e5eecdf21bdf048cef7cb9e52bf573fdf959d491/nixos/common/serial.nix#L66-L71
- https://github.com/nix-community/srvos/blob/a3f6322dfa62aa40dc4faa9d5b2f1542a6e9a95d/nixos/common/serial.nix#L29-L52
