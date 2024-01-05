


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

