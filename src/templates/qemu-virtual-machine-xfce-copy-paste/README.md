


```bash
nix \
run \
--refresh \
github:ES-nix/es#installQEMUVirtualMachineXfceCopyPasteTemplate \
&& cd QEMUVirtualMachineXfceCopyPaste

rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#vm
```

