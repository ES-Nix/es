


```bash
nix \
run \
--refresh \
github:ES-nix/es#installQEMUVirtualMachineXfceCopyPasteMinimalTemplate \
&& cd QEMUVirtualMachineXfceCopyPasteMinimal
```


```bash
rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#vm
```

