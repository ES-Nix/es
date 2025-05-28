#!/usr/bin/env bash


# $(nix eval --impure --raw --expr 'builtins.currentSystem').

mkdir -pv QEMUVirtualMachineXfceCopyPasteMinimal \
&& cd QEMUVirtualMachineXfceCopyPasteMinimal \
&& nix \
--refresh \
flake \
init \
--template \
github:ES-nix/es#QEMUVirtualMachineXfceCopyPasteMinimal

direnv allow

git init \
&& git status \
&& git add . \
&& git status \
&& nix \
   flake \
   lock \
   --override-input nixpkgs github:NixOS/nixpkgs/c1be43e8e837b8dbee2b3665a007e761680f0c3d \
   --override-input flake-utils github:numtide/flake-utils/5aed5285a952e0b949eb3ba02c12fa4fcfef535f

rm -fv nixos.qcow2
nix run --impure --refresh --verbose .#vm

for i in {0..100};do
  if remote-viewer spice://localhost:3001
  then
    break
  fi

  date +'%d/%m/%Y %H:%M:%S:%3N'
  sleep 1
done;
