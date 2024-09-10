


```bash
nix \
run \
--refresh \
github:ES-nix/es#installQEMUVirtualMachineXfceCopyPasteTemplate \
&& cd QEMUVirtualMachineXfceCopyPaste
```


```bash
rm -fv nixos.qcow2;
nix run --impure --refresh --verbose '.#'
```



References:
- https://github.com/NixOS/nixpkgs/issues/84105#issuecomment-674727693
- https://dataswamp.org/~solene/2021-05-08-openbsd-vmm-nixos.html
- https://github.com/nix-community/srvos/blob/e5eecdf21bdf048cef7cb9e52bf573fdf959d491/nixos/common/serial.nix#L66-L71
- https://github.com/nix-community/srvos/blob/a3f6322dfa62aa40dc4faa9d5b2f1542a6e9a95d/nixos/common/serial.nix#L29-L52




If you try to update the copy/paste is broken after the end of 22.11.
```bash
nix \
flake \
lock \
--override-input nixpkgs 'github:NixOS/nixpkgs/70bdadeb94ffc8806c0570eb5c2695ad29f0e421' \
--override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a'
```


```bash
nix flake metadata github:NixOS/nixpkgs/nixos-23.05
```

```bash
Resolved URL:  github:NixOS/nixpkgs/70bdadeb94ffc8806c0570eb5c2695ad29f0e421
Locked URL:    github:NixOS/nixpkgs/70bdadeb94ffc8806c0570eb5c2695ad29f0e421
Description:   A collection of packages for the Nix package manager
Path:          /nix/store/4a3qxnlq7r1gjwfjfqrizpf30hh22bz1-source
Revision:      70bdadeb94ffc8806c0570eb5c2695ad29f0e421
Last modified: 2024-01-03 11:06:54
Inputs:
```


TODO: make it minimal, now it has zsh and more custom stuff.
